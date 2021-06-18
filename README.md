## Pure Storage PowerShell Example Scripts
### EXAMPLE SCRIPTS
* Set-IscsiTcpSettings.ps1 -- Script to disable Nagle (TcpNoDelay) and TcpAckFrequency on a per adapter basis.
* [Get-PfaRASession.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Get-PfaRASession.ps1) -- Blog post: [Checking for Active Remote Assist Session](http://www.purepowershellguy.com/?p=12631)
* [Get-PfaConnections.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Get-PfaConnections.ps1) -- Blog post: [What Volume is Connected to What Host?](http://www.purepowershellguy.com/?p=10312)
* [Get-PfaCapacitySummary.ps1](https://github.com/PureStorage-OpenConnect/powershell-scripts/blob/master/Get-PfaCapacitySummary.ps1) -- A basic script that surveys PFA fleet and outputs aggregated capacity summary.
* [New-TestMailboxSetup.ps1]()
* [New-FlashStackExchangeSetup.ps1]()
* [Show-VolumeSnapshotRelationship.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Show-VolumeSnapshotRelationship.ps1) -- Blog post: [Correlate a Volume to Source Snapshot](http://www.purepowershellguy.com/?p=11091)
* [Get-ADMembers.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Get-PfaConnections.ps1) -- Blog post: [Retrieving Members of Directory Service Configuration](http://www.purepowershellguy.com/?p=12121)
* [Get-DisconnectedVolumes.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Get-DisconnectedVolumes.ps1) -- Blog post: [Find All Disconnected Volumes](http://www.purepowershellguy.com/?p=12201)
* [Get-GitHubRelDownloads.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Get-GitHubRelDownloads.ps1) -- Blog post: [Get GitHub Download Release Metrics](http://www.purepowershellguy.com/?p=12271)
* [Show-HierarchyVisualization.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Show-HierarchyVisualization.ps1) -- Blog post: [Create a Hierarchy Tree of Hosts, Volumes & Snapshots](http://www.purepowershellguy.com/?p=12401)
* [Disable-DefragScheduledTasks.ps1](https://github.com/barkz/PurePowerShellGuy/blob/master/Disable-DefragScheduledTask.ps1) -- Blog post: [Best Practice: Disable Disk Fragmentation Scheduled Task](http://www.purepowershellguy.com/?p=12471)
* [PRTG_PureFA-HW.ps1](https://github.com/barkz/powershell-scripts/blob/master/PRTG_PureFA-HW.ps1) -- Simple PRTG custom sensor to monitor Pure Storage FlashArray hardware components
* [PRTG_PureFA-Perf.ps1](https://github.com/barkz/powershell-scripts/blob/master/PRTG_PureFA-Perf.ps1) -- Simple PRTG custom example to monitor Pure Storage FlashArray performance.
* [PRTG_PureFA-Volume.ps1](https://github.com/barkz/powershell-scripts/blob/master/PRTG_PureFA-Volume.ps1) -- Simple PRTG custom sensor to monitor Pure Storage FlashArray volumes

### RELEASE COMPATIBILITY

* The scripts intended for FlashArrays are only compatable with the SDK version 1.x.
* These scripts require PowerShell 3.0 or higher..
* These scripts require an operating system that supports the TLS 1.1/1.2 protocols.


*This repository contains some sample scripts that were orignally posted to https://purepowershellguy.com.*