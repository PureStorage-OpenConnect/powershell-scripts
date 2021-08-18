#Requires -RunAsAdministrator
<#
  Get-WindowsDiagnosticInfo.ps1 - https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-WindowsDiagnosticInfo.ps1
  Version:        1.0.0.0
  Author:         Mike Nelson @ Pure Storage
.SYNOPSIS
  Gathers Windows operating system, hardware, and software information, including logs for diagnostics. This cmdlet requires Administrative permissions.
.DESCRIPTION
  This script will collect detailed information on the Windows operating system, hardware and software components, and collect event logs in .evtx and .csv formats. It will optionally collect WSFC logs and optionally compress all gathered files intoa .zip file for easy distribution.
  This script will place all of the files in a parent folder in the root of the C:\ drive that is named after the computer NetBios name($env:computername).
  Each section of information gathered will have it's own child folder in that parent folder.
.PARAMETER Cluster
  Optional. Collect Windows Server Failover Cluster (WSFC) logs.
.PARAMETER Compress
  Optional. Compress the folder that contains all the gathered data into a zip file. The file name will be the computername_diagnostics.zip.
.INPUTS
  None
.OUTPUTS
  Diagnostic outputs in txt and event log files.
  Compressed zip file.
.EXAMPLE
Get-WindowsDiagnosticInfo.ps1 -Cluster

Retrieves all of the operating system, hardware, software, event log, and WSFC logs into the default folder.

.EXAMPLE
Get-WindowsDiagnosticInfo.ps1 -Compress

Retrieves all of the operating system, hardware, software, event log, and compresses the parent folder into a zip file that will be created in the root of the C: drive.

.NOTES
This cmdlet requires Administrative permissions.
#>
<#
.DISCLAIMER
You running this code means you will not blame the author(s) if this breaks your stuff. This script/function is provided AS IS without warranty of any kind. Author(s) disclaim all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall author(s) be held liable for any damages whatsoever arising out of the use of or inability to use the script or documentation.
#>

[cmdletbinding()]
Param(
    [Parameter(ValuefromPipeline = $false, Mandatory = $false)][switch]$Cluster,
    [Parameter(ValuefromPipeline = $false, Mandatory = $false)][switch]$Compress
)
# create root outfile
$folder = Test-Path -PathType Container -Path "c:\$env:computername"
if ($folder -eq "False") {
New-Item -Path "c:\$env:computername" -ItemType "directory" | Out-Null
}
Set-Location -Path "c:\$env:computername"
Write-Host ""

# system information
Write-Host "Retrieving MSInfo32 information. This will take some time to complete. Please wait..." -ForegroundColor Yellow
msinfo32 /report msinfo32.txt | Out-Null
Write-Host "Completed MSInfo32 information." -ForegroundColor Green
Write-Host ""
## hotfixes
Write-Host "Retrieving Hotfix information..." -ForegroundColor Yellow
Get-WmiObject -Class Win32_QuickFixEngineering | Select-Object -Property Description, HotFixID, InstalledOn | Format-Table -Wrap -AutoSize | Out-File  "HotfixesQFE.txt"
Get-HotFix | Format-Table -Wrap -AutoSize | Out-File "Get-Hotfix.txt"
Write-Host "Completed HotfixQFE information." -ForegroundColor Green
Write-Host ""

# storage information
New-Item -Path "c:\$env:computername\storage" -ItemType "directory" | Out-Null
Set-Location -Path "c:\$env:computername\storage"
Write-Host "Retrieving Storage information..." -ForegroundColor Yellow
fsutil behavior query DisableDeleteNotify | Out-File "fsutil_behavior_DisableDeleteNotify.txt"
Get-PhysicalDisk | Select-Object * | Out-File "Get-PhysicalDisk.txt"
Get-Disk | Select-Object * | Out-File "Get-Disk.txt"
Get-Volume | Select-Object * | Out-File "Get-Volume.txt"
Get-Partition | Select-Object * | Out-File "Get-Partition.txt"
Write-Host "    Completed Disk information." -ForegroundColor Green
Write-Host ""
## disk, MPIO, and MSDSM information
Write-Host "    Retrieving MPIO and MSDSM information..." -ForegroundColor Yellow
Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\MSDSM\Parameters" | Out-File "Get-ItemProperty_msdsm.txt"
Get-MSDSMGlobalDefaultLoadBalancePolicy | Out-File "Get-ItemProperty_msdsm_load_balance_policy.txt"
Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\mpio\Parameters" | Out-File "Get-ItemProperty_mpio.txt"
Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Disk" | Out-File "Get-ItemProperty_disk.txt"
mpclaim -s -d | Out-File "mpclaim_-s_-d.txt"
mpclaim -v | Out-File "mpclaim_-v.txt"
Get-MPIOSetting | Out-File "Get-MPIOSetting.txt"
Get-MPIOAvailableHW | Out-File "Get-MPIOAvailableHW.txt"
Write-Host "    Completed MPIO, & MSDSM information." -ForegroundColor Green
Write-Host ""
## Fibre Channel information
Write-Host "    Retrieving Fibre Channel information..." -ForegroundColor Yellow
winrm e wmi/root/wmi/MSFC_FCAdapterHBAAttributes > MSFC_FCAdapterHBAAttributes.txt
winrm e wmi/root/wmi/MSFC_FibrePortHBAAttributes > MSFC_FibrePortHBAAttributes.txt
Get-InitiatorPort | Out-File "Get-InitiatorPort.txt"
Write-Host "    Completed Fibre Channel information." -ForegroundColor Green
Write-Host ""
Write-Host "Completed Storage information." -ForegroundColor Green
Write-Host ""

# Network information
New-Item -Path "c:\$env:computername\network" -ItemType "directory" | Out-Null
Set-Location -Path "c:\$env:computername\network"
Write-Host "Retrieving Network information..." -ForegroundColor Yellow
Get-NetAdapter | Format-Table Name,ifIndex,Status,MacAddress,LinkSpeed,InterfaceDescription -AutoSize | Out-File "Get-NetAdapter.txt"
Get-NetAdapterAdvancedProperty | Format-Table DisplayName, DisplayValue, ValidDisplayValues | Out-File "Get-NetAdapterAdvancedProperty.txt" -Width 160
Write-Host "Completed Network information." -ForegroundColor Green
Write-Host ""

# Event Logs in evtx format
New-Item -Path "c:\$env:computername\eventlogs" -ItemType "directory" | Out-Null
Set-Location -Path "c:\$env:computername\eventlogs"
Write-Host "Retrieving Event Logs unfiltered." -ForegroundColor Yellow
wevtutil epl System "systemlog.evtx"
wevtutil epl Setup "setuplog.evtx"
wevtutil epl Security "securitylog.evtx"
wevtutil epl Application "applicationlog.evtx"
Write-Host "   Completed .evtx log files." -ForegroundColor Green
## create locale files
wevtutil al "systemlog.evtx"
wevtutil al "setuplog.evtx"
wevtutil al "securitylog.evtx"
wevtutil al "applicationlog.evtx"
Write-Host "   Completed locale .evtx log files." -ForegroundColor Green
## get error & warning events & export to csv
Write-Host "Retrieving filtered Event Logs. This will take some time to complete. Please wait..." -ForegroundColor Yellow
Get-WinEvent -FilterHashtable @{LogName = 'Application'; 'Level' = 1, 2, 3} -ErrorAction SilentlyContinue | Export-Csv "application_log-CRITICAL_ERROR_WARNING.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'System'; 'Level' = 1, 2, 3 } -ErrorAction SilentlyContinue | Export-Csv "system_log-CRITICAL_ERROR_WARNING.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'Security'; 'Level' = 1, 2, 3 } -ErrorAction SilentlyContinue | Export-Csv "security_log-CRITICAL_ERROR_WARNING.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'Setup'; 'Level' = 1, 2, 3 } -ErrorAction SilentlyContinue | Export-Csv "setup_log-CRITICAL_ERROR_WARNING.csv" -NoTypeInformation
Write-Host "   Completed Critical, Error, & Warning .csv log files." -ForegroundColor Green
## get information events & export to csv
Get-WinEvent -FilterHashtable @{LogName = 'Application'; 'Level' = 4 } -ErrorAction SilentlyContinue | Export-Csv "application_log-INFO.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'System'; 'Level' = 4 } -ErrorAction SilentlyContinue | Export-Csv "system_log-INFO.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'Security'; 'Level' = 4 } -ErrorAction SilentlyContinue | Export-Csv "security_log-INFO.csv" -NoTypeInformation
Get-WinEvent -FilterHashtable @{LogName = 'Setup'; 'Level' = 4 } -ErrorAction SilentlyContinue | Export-Csv "setup_log-INFO.csv" -NoTypeInformation
Write-Host "   Completed Informational .csv log files." -ForegroundColor Green
Write-Host ""
Write-Host "Completed Event Logs." -ForegroundColor Green
Write-host ""

# WSFC inforation
If ($Cluster.IsPresent) {
    New-Item -Path "c:\$env:computername\cluster" -ItemType "directory" | Out-Null
    Set-Location -Path "c:\$env:computername\cluster"
    Write-Host "Retrieving Cluster Logs. This may take some time to complete. Please wait..." -ForegroundColor Yellow
    Get-ClusterLog -Destination . | Out-Null
    Get-ClusterSharedVolume | Select-Object * | Out-File "Get-ClusterSharedVolume.txt"
    Get-ClusterSharedVolumeState | Select-Object * | Out-File "Get-ClusterSharedVolumeState.txt"
    Write-Host "Completed Cluster information." -ForegroundColor Green
    Write-Host ""
}

# Compress folder
If ($Compress.IsPresent) {
    Write-Host "Starting folder compression. Please wait..." -ForegroundColor Yellow
    Set-Location -Path "\"
    $compress = @{
        Path = "c:\$env:computername"
        CompressionLevel = "Optimal"
        DestinationPath = $env:computername + "_diagnostics.zip"
    }
    Compress-Archive @compress
    Write-Host "Completed folder compression." -ForegroundColor Green
}
Write-host ""
Write-Host "Information collection completed."
#END