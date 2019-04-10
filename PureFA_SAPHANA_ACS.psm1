<#
.Notes
NAME: PureFA_SAPHANA_AC
AUTHOR: Andrew Sillifant
Website: https://www.purestorage.com/
Version: 0.1
CREATED: 2019/04/04
LASTEDIT: 2019/04/04

 .Synopsis
Provides and easy to use single command for the creating of application consistent storage snapshots between SAP HANA and Pure Storage Flash Array
Only Scale up supported

.Description
Only New-SAPHANAStorageSnapshot is viewable when running impor-module FlashArray_SAPHANA_SDK.psm1 , this is then executed to create application consistent snapshots
As a part of the process the filesystem is frozen and unfrozen for the SAP HANA data volume and the snapshot is either confirmed or abandonded for use. 
The catalog is managed by the SAP HANA backup catalog itself

.Parameter HostAddress
The IPv4 or V6 address of the SAP HANA host 

.Parameter InstanceNumber
The instance number of the SAP HANA deployment


.Parameter DatabaseName
The database name of the SAP HANA deployment 

.Parameter DatabaseUser
A database user with permissions to either SYSTEMDB or the ability to create storage snapshots and view the SAP HANA global.ini file

.Parameter DatabasePassword
The database password that matches to DatabaseUser

.Parameter OperatingSystemUser
An operating system user with permissions to freeze and unfreeze the SAP HANA Data volume

.Parameter OperatingSystemPassword
The password for the user specified in OperatingSystemUser

.Parameter PureFlashArrayAddress
The Pure storage FlashArray which the SAP HANA deployment resides on

.Parameter PureFlashArrayUser
A user for the Pure storage FlashArray with permissions to create snapshots and view volumes

.Parameter PureFlashArrayPassword
The password for the user specified in PureFlashArrayUser


.Example
New-SAPHANAStorageSnapshot -HostAddress <IP address of host> -InstanceNumber <Instance Number (00)> -DatabaseName <Database Name (HN1)> -DatabaseUser <DBUser> 
-OperatingSystemUser <OS-User> -PureFlashArrayAddress <Pure FlashArray IP or hostname> -PureFlashArrayUser <pure FA User> 
Create a snapshot without entering information for trhe password fields

.Example
New-SAPHANAStorageSnapshot -HostAddress <IP address of host> -InstanceNumber <Instance Number (00)> -DatabaseName <Database Name (HN1)> -DatabaseUser <DBUser> -DatabasePassword <DBPassword> 
-OperatingSystemUser <OS-User> -OperatingSystemPassword <OSPassword> -PureFlashArrayAddress <Pure FlashArray IP or hostname> -PureFlashArrayUser <pure FA User> -PureFlashArrayPassword <Pure FA Password>
Create a snapshot with all of the password fields being shown as plaintext 
#>


# After Import-Module .\FlashArray_SAPHANA_SDK.psm1 may typically need to execute:
#  Set-ExecutionPolicy Unrestricted
# to allow these to work.

# Version History
#
# 0.1a Initial Appl;ication consistent snapshots for Pure Storage Flash Array
#


##Static Non public values
$PureStorage_FlashArray_SAPHANA_Version = "0.1a"
$SnapshotTime
$GetSAPAHANASystemType
$GetDataVolumeLocation 
$CreateHDBStorageSnapshot
$RetrieveHDBSnapshotID 
$hdbConnectionString 


if( $PSVersiontable.PSVersion.Major -lt 3) {
  Write-Error  "This script requires minimum of PowerShell v3.0"
  return  
}  

function Check-ForHDBDriver()
{
   $hdbODBCCheck =  Get-OdbcDriver | Where-Object Name -EQ 'HDBODBC'
   if($hdbODBCCheck -eq $null)
   {
        Write-Host "Please install the SAP HANA client for microsoft windows"
        return $false
   }
   else
   {
        return $true
   }
}

function Check-ForPOSH-SSH()
{
    $poshSSHCHeck = Get-Module -Name Posh-SSH
    if($poshSSHCHeck -eq $null)
    {
        Write-Host "Installing POSH-SSH"
        Install-Module -Name Posh-SSH   
    }
    else
    {
        Write-Host "POSH-SSH already installed"
    }
    Import-Module Posh-SSH
}

function Check-ForPureStorageSDK()
{
    $pureSTorageSDKCheck = Get-Module -Name PureStoragePowerShellToolkit
    if($pureSTorageSDKCheck -eq $null)
    {
        Write-Host "Installing Pure Storage Powershell toolkit"
        Install-Module -Name PureStoragePowerShellToolkit 
    }
    else
    {
        Write-Host "Pure Storage Powershell toolkit already installed"
    }
    Import-Module PureStoragePowerShellToolkit
}

function Get-ODBCData() 
{
    Param($hanaConnectionString,
    $hdbsql)

    $Conn = New-Object System.Data.Odbc.OdbcConnection($hanaCOnnectionString)
    $Conn.open()
    $readcmd = New-Object System.Data.Odbc.OdbcCommand($hdbsql,$Conn)
    $readcmd.CommandTimeout = '300'
    $da = New-Object System.Data.Odbc.OdbcDataAdapter($readcmd)
    $dt = New-Object System.Data.DataTable
    [void]$da.fill($dt)
    $Conn.close()
    return $dt
}

function Check-SAPHANASystemType()
{
    $systemtype = Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $GetSAPAHANASystemType
    return $systemtype
}

function Get-VolumeSerialNumber()
{
    Param(
        $HostAddress,
        $DataVolumeMountPoint,
        $OSUser,
        $OSPassword
    )
    $Cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $OSUser, $OSPassword
		
    $output = New-SSHSession -ComputerName $HostAddress -Credential $Cred -AcceptKey:$True -ConnectionTimeout 60000
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep -Seconds 1
    $output = $stream.Read()
    $stream.WriteLine("df -h | grep " + $DataVolumeMountPoint)
    #Start-Sleep -Seconds 1
    $output = $stream.Readline()
    $dfToParse = $stream.ReadLine()
    $ParsedVolumeDevLocation = [regex]::Match($dfToParse, '(\S+)').Groups[1].Value
    $udevADMQuery = "udevadm info --query=all --name=" + $ParsedVolumeDevLocation + " | grep DM_SERIAL"
    $stream.WriteLine($udevADMQuery)
    $output = $stream.ReadLine()
    $queryResponse = $stream.ReadLine()
    $volSerialNumber = ($queryResponse.split('='))[1]
    $output = Remove-SSHSession $session
    return $volSerialNumber
}

function Create-PureStorageVolumeSnapshot()
{
    Param(
        $FlashArrayAddress, 
        $User, 
        $Password,
        $SerialNumber, 
        $SnapshotSuffix
    )

    $Array = New-PfaArray -EndPoint $FlashArrayAddress -username $User -Password $Password -IgnoreCertificateError
    $Volumes = Get-PfaVolumes -Array $Array #| Where-Object $serialNumber.ToUpper -Contains serial

    foreach($vol in $Volumes)
    {
        if($serialNumber.Contains($vol.serial.tolower()))
        {
            Write-Host "Volume located, creating snapshot"
            $VolumeSnapshot = New-PfaVolumeSnapshots -Array $Array -Sources $vol.name -Suffix $SnapshotSuffix
            if(!($VolumeSnapshot.name -eq $null))
            {
                Write-host "Snapshot name : " $VolumeSnapshot.name 
                return $VolumeSnapshot.serial
            }
            else
            {
                return $null
            }
        }
    }
}

function Create-SAPHANADatabaseSnapshot()
{
    Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $CreateHDBStorageSnapshot
    $hdbSnapshot = Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $RetrieveHDBSnapshotID
    return $hdbSnapshot
}

function FreezeFileSystem()
{
    param(
        $HostAddress, 
        $OSUser,
        $OSPassword,
        $FilesystemMount
    )
    $Cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $OSUser, $OSPassword 
		
    $output = New-SSHSession -ComputerName $HostAddress -Credential $Cred -AcceptKey:$True -ConnectionTimeout 60000
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep -Seconds 1
    $output = $stream.Read()
    $stream.WriteLine(" /sbin/fsfreeze -f " + $FilesystemMount)
    $output = Remove-SSHSession $session
}

function UnFreezeFileSystem()
{
    param(
        $HostAddress, 
        $OSUser,
        $OSPassword,
        $FilesystemMount
    )
    $Cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $OSUser, $OSPassword 
		
    $output = New-SSHSession -ComputerName $HostAddress -Credential $Cred -AcceptKey:$True -ConnectionTimeout 60000
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep -Seconds 1
    $output = $stream.Read()
    $stream.WriteLine(" /sbin/fsfreeze -u " + $FilesystemMount)
    $output = Remove-SSHSession $session
}

function Abandon-SAPHANADatabaseSnapshot()
{
    Param(
        $BackupID
    )
    $FailureTime = "{0:yyyy-MM-dd HH:mm:ss}" -f (get-date)
    $AbandonHDBSnapshot = "BACKUP DATA FOR FULL SYSTEM CLOSE SNAPSHOT BACKUP_ID " + $BackupID + " UNSUCCESSFUL '" + $FailureTime + "';"
    Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $AbandonHDBSnapshot
}

function Confirm-SAPHANADatabaseSnapshot()
{
    Param(
        $ExternalBackupID
    )
    $SuccessTime = "{0:yyyy-MM-dd HH:mm:ss}" -f (get-date)
    $ConfirmHDBSnapshot = "BACKUP DATA FOR FULL SYSTEM CLOSE SNAPSHOT BACKUP_ID " + $ExternalBackupID + " SUCCESSFUL '" + $SuccessTime + "';"
    Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $ConfirmHDBSnapshot
}

function AskSecureQ ([String]$Question, [String]$Foreground="Yellow", [String]$Background="Blue") {
    Write-Host $Question -ForegroundColor $Foreground -BackgroundColor $Background -NoNewLine
    Return (Read-Host -AsSecureString)
}

function AskInSecureQ ([String]$Question, [String]$Foreground="Yellow", [String]$Background="Blue") {
    Write-Host $Question -ForegroundColor $Foreground -BackgroundColor $Background -NoNewLine
    Return (Read-Host)
}

Function New-SAPHANAStorageSnapshot()
{
    Param(
    [parameter(Mandatory=$True)]
    [string]$HostAddress
    ,
    [parameter(,Mandatory=$True)]
    [string]$InstanceNumber
    ,
    [parameter(Mandatory=$True)]
    [string]$DatabaseName
    ,
    [parameter(Mandatory=$True)]
    [string]$DatabaseUser
    ,
    [Parameter(Mandatory = $False)]
    $DatabasePassword
    ,
    [parameter(Mandatory=$True)]
    [string]$OperatingSystemUser
    ,
    [Parameter(Mandatory = $False)]
    $OperatingSystemPassword
    ,
    [parameter(Mandatory=$True)]
    [string]$PureFlashArrayAddress
    ,
    [parameter(Mandatory=$True)]
    [string]$PureFlashArrayUser
    ,
    [Parameter(Mandatory = $False)]
    $PureFlashArrayPassword
    )



    if ($DatabasePassword) {
    #$DatabasePassword = $DatabasePassword 
    } else {
        $DatabasePassword = AskInSecureQ "Type in Database password "
    }

    if ($OperatingSystemPassword) {
    $OperatingSystemPassword =  ConvertTo-SecureString -String $OperatingSystemPassword -AsPlainText -Force
    } else {
        $OperatingSystemPassword = AskSecureQ "Type in Operating System password"
        }
 

    if ($PureFlashArrayPassword) {
    $PureFlashArrayPassword = ConvertTo-SecureString -String $PureFlashArrayPassword -AsPlainText -Force
    } else {
        $PureFlashArrayPassword = AskSecureQ "Type in Pure FlashArray password"
    }

    $SnapshotTime = "{0:yyyy-MM-dd HH:mm:ss}" -f (get-date)
    $GetSAPAHANASystemType = "SELECT VALUE FROM M_INIFILE_CONTENTS WHERE FILE_NAME = 'global.ini' AND SECTION = 'multidb' AND KEY = 'mode'"
    $GetDataVolumeLocation = "SELECT VALUE FROM M_INIFILE_CONTENTS WHERE FILE_NAME = 'global.ini' AND SECTION = 'persistence' AND KEY = 'basepath_datavolumes'"
    $CreateHDBStorageSnapshot = "BACKUP DATA FOR FULL SYSTEM CREATE SNAPSHOT COMMENT 'SNAPSHOT-" + $SnapshotTime +"';"
    $RetrieveHDBSnapshotID = "SELECT BACKUP_ID, COMMENT FROM M_BACKUP_CATALOG WHERE ENTRY_TYPE_NAME = 'data snapshot' AND STATE_NAME = 'prepared' AND COMMENT = 'SNAPSHOT-" + $SnapshotTime +"';"
    $hdbConnectionString = "Driver={HDBODBC};ServerNode=" + $HostAddress + ":3" + $InstanceNumber + "15;UID=" + $DatabaseUser + ";PWD=" + $DatabasePassword +";"
    $multiDB = $false

    ##Check for necessary HDB Client Installation
    if(Check-ForHDBDriver)
    {
        ##Check for required libraries for SSH and Pure Storage SDK
        Check-ForPOSH-SSH
        Check-ForPureStorageSDK
        ##Check the SAP HANA system type for multiDB or single tenant DB
        $SystemType = Check-SAPHANASystemType
        if($SystemType.VALUE -eq 'multidb')
        {
            $hdbConnectionString = "Driver={HDBODBC};ServerNode=" + $HostAddress + ":3" + $InstanceNumber + "13;UID=" + $DatabaseUser + ";PWD=" + $DatabasePassword +";"
            $multiDB = $true
        }
        ##Get the volume serial number 
        $ShortMountPath = ((Get-ODBCData -hanaConnectionString $hdbConnectionString -hdbsql $GetDataVolumeLocation).VALUE).Replace("/" + $DatabaseName,"")
        if($multiDB)
        {
            $ShortMountPath = $ShortMountPath[1]
        }
        $SerialNumber =  Get-VolumeSerialNumber -HostAddress $HostAddress -OSUser $OperatingSystemUser -OSPassword $OperatingSystemPassword -DataVolumeMountPoint $ShortMountPath

        ##Prepare HANA Storage Snapshot
        Write-Host "Preparing SAP HANA Snapshot"
        $HANASnapshot = Create-SAPHANADatabaseSnapshot 

        ##Freeze the filesystem
        Write-Host "Freezing filesystem"
        FreezeFileSystem -HostAddress $HostAddress -OSUser $OperatingSystemUser -OSPassword $OperatingSystemPassword -FilesystemMount $ShortMountPath


        ##Create Pure Volume Snapshot
        $SnapshotSuffix = "SAPHANA-" + $HANASnapshot.BACKUP_ID.ToString()
        $snapshotSerial = Create-PureStorageVolumeSnapshot -FlashArrayAddress $PureFlashArrayAddress -User $PureFlashArrayUser -Password $PureFlashArrayPassword -SerialNumber $serialNumber -SnapshotSuffix $SnapshotSuffix
        ##Unfreeze the filesystem
        Write-Host "Unfreezing filesystem"
        UnFreezeFileSystem -HostAddress $HostAddress -OSUser $OperatingSystemUser -OSPassword $OperatingSystemPassword -FilesystemMount $ShortMountPath
        if(!($snapshotSerial -eq $null))
        {
            Write-Host "Confirming Snapshot"
            Confirm-SAPHANADatabaseSnapshot -ExternalBackupID $HANASnapshot.BACKUP_ID.ToString()
        }
        else
        {
            Write-Host "Abandoning Snapshot"
            Abandon-SAPHANADatabaseSnapshot -BackupID $HANASnapshot.BACKUP_ID.ToString()
        }
    }
}


############################################
#    Exports for visibility                #
############################################

Export-ModuleMember -Function 'New-SAPHANAStorageSnapshot'
