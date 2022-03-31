<#
New-FlashArrayExcelReport.ps1
version 1.0.0
Original script credit to Seteesh1 in the Pure Storage Community Forums

.SYNOPSIS
    Create a Excel workbook that contains FlashArray Information
    .DESCRIPTION
    This cmdlet will retrieve array, volume, host, pod, and snapshot capacity information from all of the FlashArrays listed in the txt file and output it to an Excel spreadsheet. Each arrays will have it's own filename and the current date and time will be added to the filenames.
    .PARAMETER Username
    Optional. Full username to login to the arrays. This currently must be the same username for all arrays. This user must have the array-admin role.
    If not supplied, the $Creds variable must exist in the session and be set by Get-Credential.
    .PARAMETER PassFilePath
    Optional. Full path and filename that contains the plaintext password for the $username. The password will be encrypted when passing to the array.
    If not supplied, the $Creds variable must exist in the session and be set by Get-Credential.
    .PARAMETER ArrayList
    Required. Full path to file name that contains IP addresses or FQDN's for all FlashAarays being reported on. This is a plain text file with each array on a new line.
    .PARAMETER OutPath
    Optional. Full directory path (with no trailing "\") for Excel workbook, formatted as DRIVE_LETTER:\folder_name. If not specified, the files will be placed in the %temp% folder.
    .PARAMETER snapLimit
    Optional. This will limit the total number of Volume snapshots returned from the arrays. This will be beneficial when working with a large number of snapshots. With a large number of snapshots, and not setting this limit, the worksheet creation time is increased considerably.
    .INPUTS
    None
    .OUTPUTS
    An Excel workbook
    .EXAMPLE
    New-FlashArrayExcelReport -Username "pureuser" -PassFilePath "c:\temp\creds.txt" -ArrayList "c:\temp\arrays.txt"

    Creates an Excel file in the the %temp% folder for each array in the Arrays.txt file, using the username and plaintext password file supplied.

    .EXAMPLE
    $Creds = (Get-Credential)
    New-FlashArrayExcelReport -ArrayList "c:\temp\arrays.txt" -snapLimit 25 -OutPath "c:\outputs"

    Creates an Excel file for each array in the Arrays.txt file, using the credentials preconfigured via the Get-Credentials cmdlet supplied.

    .NOTES
    This cmdlet can utilize the global $Creds variable for FlashArray authentication. Set the variable $Creds by using the command $Creds = Get-Credential.
    This cmdlet requires the PowerShell module ImportExcel.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Arraylist,
        [Parameter(Mandatory = $False)][string] $OutPath = "$env:Temp",
        [Parameter(Mandatory = $False)][string] $snapLimit,
        [Parameter(Mandatory = $False)][string] $Username,
        [Parameter(Mandatory = $False)][string] $PassFilePath
    )

# Check for Creds
if (!($Creds)) {
            $pass = Get-Content -Path $PassFilePath | ConvertTo-SecureString
            $Creds = New-Object System.Management.Automation.PSCredential($username,$pass)
    }

# Check for modules & features
    Write-Host "Checking for modules and installing if necessary..." -ForegroundColor green
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $modulesArray = @(
            "PureStoragePowerShellSDK2",
            "ImportExcel"
        )
        ForEach ($mod in $modulesArray) {
            If (Get-Module -ListAvailable $mod) {
                Continue
            }
            Else {
                Install-Module $mod -Force -ErrorAction 'SilentlyContinue'
                Import-Module $mod -ErrorAction 'SilentlyContinue'
            }
        }
# Assign variables
$arrays = Get-Content -Path $arraylist
$date = (Get-Date).ToString("MMddyyyy_HHmmss")
# Run through each array
Write-Host "Starting to read from array..." -ForegroundColor green
foreach ($array in $arrays)
{
$flasharray = Connect-Pfa2Array -Endpoint $array -Credential $Creds -IgnoreCertificateError
$array_details = Get-Pfa2Array -Array $flasharray
$host_details =Get-Pfa2Host -Array $flasharray -sort "name"
$hostgroup = Get-Pfa2HostGroup -Array $flasharray
$vol_details = Get-Pfa2Volume -Array $flasharray -Sort "name" -Filter "not(contains(name,'vvol'))"
$vvol_details = Get-Pfa2Volume -Array $flasharray -Sort "name" -Filter "contains(name,'vvol')"
$pgd = Get-Pfa2ProtectionGroup -Array $flasharray
$pgst = Get-Pfa2ProtectionGroupSnapshotTransfer -Array $flasharray -Sort "name"
$controller0_details =  Get-Pfa2Controller -Array $flasharray | Where-Object Name -eq CT0
$controller1_details =  Get-Pfa2Controller -Array $flasharray | Where-Object Name -eq CT1
$free = $array_details.capacity - $array_details.space.TotalPhysical
if($PSBoundParameters.ContainsKey('snaplimit')) {
    $snapshots = Get-Pfa2VolumeSnapshot -Array $FlashArray -Limit $snapLimit
}
else {
    $snapshots = Get-Pfa2VolumeSnapshot -Array $FlashArray
}
$pods = Get-Pfa2Pod -Array $FlashArray
Write-Host "Read complete. Disconnecting and continuing..." -ForegroundColor green
# Disconnect 'cause we don't need to waste the connection anymore
Disconnect-Pfa2Array -Array $flasharray

# name and path the files
$wsname = $array_details.name
$excelFile = "$outPath\$wsname-$date.xlsx"
Write-Host "Writing data to Excel workbook..." -ForegroundColor green
# Array Information
[PSCustomObject]@{
"Array Name" = ($array_details.Name).ToUpper()
"Array ID" = $array_details.Id
"Purity Version" = $array_details.Version
"CT0-Mode" = $controller0_details.Mode
"CT0-Status" = $controller0_details.Status
"CT1-Mode" = $controller1_details.Mode
"CT1-Status" = $controller1_details.Status
"% Utilized" = "{0:P}" -f ($array_details.space.TotalPhysical / $array_details.capacity )
"Total Capacity(TB)" = [math]::round($array_details.Capacity/1024/1024/1024/1024,2)
"Used Capacity(TB)" = [math]::round($array_details.space.TotalPhysical/1024/1024/1024/1024,2)
"Free Capacity(TB)" = [math]::round($free/1024/1024/1024/1024,2)
"Provisioned Size(TB)" = [math]::round($array_details.space.TotalProvisioned/1024/1024/1024/1024,2)
"Unique Data(TB)" = [math]::round($array_details.space.Unique/1024/1024/1024/1024,2)
"Shared Data(TB)" = [math]::round($array_details.space.shared/1024/1024/1024/1024,2)
"Snapshot Capacity(TB)" = [math]::round($array_details.space.snapshots/1024/1024/1024/1024,2)
} | Export-Excel $excelFile -WorksheetName "Array_Info" -AutoSize -TableName "ArrayInformation" -Title "FlashArray Information"

## Volume Details
$vol_details | Select-Object name,@{n='Size(GB)';e={[math]::round(($_.provisioned/1024/1024/1024),2)}},@{n='Unique Data(GB)';e={[math]::round(($_.space.Unique/1024/1024/1024),2)}},@{n='Shared Data(GB)';e={[math]::round(($_.space.Shared/1024/1024/1024),2)}},serial,ConnectionCount,Created,@{n='Volume Group';e={$_.VolumeGroup.Name}},Destroyed,TimeRemaining | Export-Excel $excelFile -WorksheetName "Volumes-No vVols" -AutoSize -ConditionalText $(New-ConditionalText Stop DarkRed LightPink) -TableName "VolumesNovVols" -Title "Volumes - Not including vVols"

## vVol Volume Details
$vvol_details | Select-Object name,@{n='Size(GB)';e={[math]::round(($_.provisioned/1024/1024/1024),2)}},@{n='Unique Data(GB)';e={[math]::round(($_.space.Unique/1024/1024/1024),2)}},@{n='Shared Data(GB)';e={[math]::round(($_.space.Shared/1024/1024/1024),2)}},serial,ConnectionCount,Created,@{n='Volume Group';e={$_.VolumeGroup.Name}},Destroyed,TimeRemaining | Export-Excel $excelFile -WorksheetName "vVol Volumes" -AutoSize -ConditionalText $(New-ConditionalText Stop DarkRed LightPink) -TableName "vVolVolumes" -Title "vVol Volumes"

# Host Details
$host_details | Select-Object Name,@{n='No. of Volumes';e={$_.ConnectionCount}},@{n='HostGroup';e={$_.HostGroup.Name}},Personality,@{n='Allocated(GB)';e={[math]::round(($_.space.totalprovisioned/1024/1024/1024),2)}},@{n='Wwns';e={$_.Wwns -join ',' }} | Export-Excel $excelFile -WorksheetName "Hosts" -AutoSize -TableName "Hosts" -Title "Host Information"

## HostGroup Details
$hostgroup | Select-Object Name,HostCount,@{n='No.of Volumes';e={$_.ConnectionCount}},@{n='Total Size(GB)';e={[math]::round(($_.space.totalprovisioned/1024/1024/1024),2)}} | Export-Excel $excelFile -WorksheetName "Host Groups" -AutoSize -TableName "HostGroups" -Title "Host Groups"

## ProtectionGroup Detais
$pgd | select-object Name,@{n='Snapshot Size(GB)';e={[math]::round(($_.space.snapshots/1024/1024/1024),2)}},volumecount,@{n='Source';e={$_.source.name}} | Export-Excel $excelFile -WorksheetName "Protection Groups" -AutoSize -TableName "ProtectionGroups" -Title "Protection Group"

## PG Snapshot Transfer details
$pgst | Select-Object Name,@{n='Data Transferred(MB)';e={[math]::round(($_.DataTransferred/1024/1024),2)}},Destroyed,@{n='Physical Bytes Written(MB)';e={[math]::round(($_.PhysicalBytesWritten/1024/1024),2)}},@{n="Status";e={$_.Progress -Replace("1","Transfer Complete")}}| Export-Excel $excelFile -WorksheetName "PG Snapshot Transfers" -AutoSize -TableName "PGroupSnapshotTransfers" -Title "Protection Group Snapshot Transfers"

## Volume Snapshot details
$snapshots | Select-Object Name,Created,@{n='Provisioned(GB)';e={[math]::round(($_.Provisioned/1024/1024/1024),2)}},Destroyed,@{n='Source';e={$_.Source.Name}},@{n='Pod';e={$_.pod.name}},@{n='Volume Group';e={$_.VolumeGroup.Name}} | Export-Excel $excelFile -WorksheetName "Volume Snapshots" -AutoSize -TableName "VolumeSnapshots" -Title "Volume Snapshots"

## Pod details
$pods | Select-Object Name,arraycount,@{n='Source';e={$_.source.name}},mediator,promotionstatus,destroyed | Export-Excel $excelFile -WorksheetName "Pods" -AutoSize -TableName "Pods" -Title "Pod Information"

}
Write-Host "Complete. Files located in $outpath" -ForegroundColor green
## END