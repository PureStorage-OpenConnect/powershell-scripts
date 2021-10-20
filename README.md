# Pure Storage PowerShell Example Scripts
#### These scripts are provided as examples and are freely available for modifications and use. many of these scripts have been incorprated into the [Pure PowerShell Toolkit](https://github.com/PureStorage-OpenConnect/powershell-toolkit).
#### Most of these scripts require the [Pure Storage Powerhell SDK](https://github.com/PureStorage-Connect).

### EXAMPLE SCRIPTS
Updated 10-20-2021
* [New-PfaRestSession.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/New-PfaRestSession.ps1) -- REST wrapper script created by Cody Hosterman for operations that are in the FlashArray REST, but not in the Pure Storage PowerShell SDK yet, this function provides a connection for Invoke-RestMethod to use.
* [Remove-PfaRestSession.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Remove-PfaRestSession.ps1) -- REST wrapper script written by Cody Hosterman that terminates a REST session created by New-PfaRestSession.ps1.
* [Get-WindowsDiagnosticinfo.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-WindowsDiagnosticInfo.ps1) -- Script to collect diagnostic and log information from the Windows OS.
* [Set-IscsiTcpSettings.ps1](https://github.com/PureStorage-OpenConnect/powershell-toolkit) -- Script to disable Nagle (TcpNoDelay) and TcpAckFrequency on a per adapter basis. (**This script is now included in the PowerShell Toolkit module**)
* [Get-PfaRASession.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-PfaRASession.ps1) -- Blog post: [Checking for Active Remote Assist Session](http://www.purepowershellguy.com/?p=12631)
* [Get-PfaConnections.ps1](https://github.comPureStorage-OpenConnect/powershell-scripts/blob/main/Get-PfaConnections.ps1) -- Blog post: [What Volume is Connected to What Host?](http://www.purepowershellguy.com/?p=10312)
* [Get-PfaCapacitySummary.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-PfaCapacitySummary.ps1) -- A basic script that surveys PFA fleet and outputs aggregated capacity summary.
* [New-TestMailboxSetup.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/New-TestMailboxSetup.ps1)
* [New-FlashStackExchangeSetup.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/New-FlashStackExchangeSetup.ps1)
* [Show-VolumeSnapshotRelationship.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Show-VolumeSnapshotRelationship.ps1) -- Blog post: [Correlate a Volume to Source Snapshot](http://www.purepowershellguy.com/?p=11091)
* [Get-ADMembers.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-PfaConnections.ps1) -- Blog post: [Retrieving Members of Directory Service Configuration](http://www.purepowershellguy.com/?p=12121)
* [Get-DisconnectedVolumes.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Get-DisconnectedVolumes.ps1) -- Blog post: [Find All Disconnected Volumes](http://www.purepowershellguy.com/?p=12201)
* [Get-GitHubRelDownloads.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/mmain/Get-GitHubRelDownloads.ps1) -- Blog post: [Get GitHub Download Release Metrics](http://www.purepowershellguy.com/?p=12271)
* [Show-HierarchyVisualization.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Show-HierarchyVisualization.ps1) -- Blog post: [Create a Hierarchy Tree of Hosts, Volumes & Snapshots](http://www.purepowershellguy.com/?p=12401)
* [Disable-DefragScheduledTasks.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Disable-DefragScheduledTask.ps1) -- Blog post: [Best Practice: Disable Disk Fragmentation Scheduled Task](http://www.purepowershellguy.com/?p=12471)
* [PRTG_PureFA-HW.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/PRTG_PureFA-HW.ps1) -- Simple PRTG custom sensor to monitor Pure Storage FlashArray hardware components
* [PRTG_PureFA-Perf.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/PRTG_PureFA-Perf.ps1) -- Simple PRTG custom example to monitor Pure Storage FlashArray performance.
* [PRTG_PureFA-Volume.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/PRTG_PureFA-Volume.ps1) -- Simple PRTG custom sensor to monitor Pure Storage FlashArray volumes
* [Update-UserPassword.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/main/Update-UserPassword.ps1) -- Simple PRTG custom sensor to monitor Pure Storage FlashArray volumes

### RELEASE COMPATIBILITY

* The scripts intended for FlashArrays are only currently compatable with the SDK version 1.x.
* These scripts require PowerShell 3.0 or higher.
* These scripts require an operating system that supports the TLS 1.1/1.2 protocols.


*This repository contains some sample scripts that were orignally posted to https://purepowershellguy.com.*
