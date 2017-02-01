#Connect to Pure Storage FlashArray
$returnIP = "10.21.8.17"
$GoldVolume = 'GOLD'
$DevVolume = 'DEV'
$DevVolumeLabel = 'DEV'
$MountPoint = 'C:\MOUNT\'
$user = "pureuser"

# Only required to run once to create secure-credentials.txt file
###Read-Host -Prompt 'Password' -AsSecureString | ConvertFrom-SecureString | Out-File 'C:\temp\Secure-Credentials.txt'

# Read secure password
$Pwd = Get-Content ‘C:\Temp\Secure-Credentials.txt’ #| ConvertTo-SecureString
$Creds = New-Object System.Management.Automation.PSCredential ($user, $pwd)
    
# Connect to Pure Storage FlashArray
$FlashArray = New-PfaArray -EndPoint $returnIP -Credentials $Creds -IgnoreCertificateError

# Create snapshot of GOLD volume
$LatestSnapshot = New-PfaVolumeSnapshots -Array $FlashArray -Sources 'GOLD'

# Overwrite DEV volume with latest GOLD snapshot
$Dev = New-PfaVolume -Array $FlashArray -Source $LatestSnapshot.name -VolumeName 'DEV' -Overwrite

$AllDevices = Get-WmiObject -Class Win32_DiskDrive -Namespace 'root\CIMV2' | Sort Index

ForEach ($Device in $AllDevices) {

    If($Device.SerialNumber -eq $Dev.serial) {
        $diskId = $Device.index
        $cmds = "`"SELECT DISK $diskId`"",
		"`"ONLINE DISK NOERR`""
		$scriptblock = [string]::Join(",", $cmds)
		$diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART") 
		Invoke-Command -ComputerName localhost -ScriptBlock $diskpart | Out-Null
        
        $part_query = 'ASSOCIATORS OF {Win32_DiskDrive.DeviceID="' + $Device.DeviceID.replace('\','\\') + '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition'
        $partitions = @(Get-WmiObject -Query $part_query | Sort StartingOffset )
        foreach ($partition in $partitions) {
 
            $vol_query = 'ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' + $partition.DeviceID + '"} WHERE AssocClass=Win32_LogicalDiskToPartition'
            $volumes   = @(Get-WmiObject -Query $vol_query)

            foreach ($volume in $volumes) {
                $volname = ($volume.name).Replace(':','')
                $cmds = "`"SELECT VOLUME=$volname`"",
                "`"ASSIGN MOUNT=$($MountPoint)`""
		        $scriptblock = [string]::Join(",", $cmds)
		        $diskpart = $ExecutionContext.InvokeCommand.NewScriptBlock("$scriptblock | DISKPART")
		        Invoke-Command -ComputerName localhost -ScriptBlock $diskpart | Out-Null
            }
        }
        Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceId = '$($volume.name)'" | Set-WmiInstance -Arguments @{VolumeName="DEV-$($LatestSnapshot.name)"} | Out-Null
    }
}
