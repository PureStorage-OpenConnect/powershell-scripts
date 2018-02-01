<#

.SYNOPSIS

Simple PRTG custom sensor for Pure Storage FlashArrays volumes monitoring.

.DESCRIPTION

This custom sensor script retrieves the volume indicators from a Pure Storage FlashArray and returns them as channels in PRTG JSON format.
The script uses the PureStorage PowerShell SDK that must be installed on the probing host.

.PARAMETER EndPoint

A single computer name of a FlashArray. You may also provide the IP address.


.PARAMETER ApiToken


The API authentication token for the target FlashArray.

.PARAMETER Volname


The name of the volume to retrieve indicators


.EXAMPLE


PRTG_PureFA-Volume -EndPoint 172.16.0.12 -ApiToken cef628f0-831b-30b9-4494-4e8ea56c207c -Volname voume01

#>


Param (
   [Parameter(Mandatory=$True,Position=1)]
   [string]$endpoint,
   [Parameter(Mandatory=$True,Position=2)]
   [string]$apitoken,
   [Parameter(Mandatory=$True,Position=3)]
   [string]$volname
)

$FA = New-PfaArray -EndPoint $endpoint -ApiToken $apitoken -IgnoreCertificateError

$v_spc = Get-PfaVolumeSpaceMetrics -Array $FA -VolumeName $volname
Disconnect-PfaArray -Array $FA

$prtgSens = @{}
$prtgSens.prtg = @{}
$prtgSens.prtg.result = @( 

@{ "channel" = "provisioned size"; "value" = [string]$v_spc.size; "unit" = "BytesDisk"; "VolumeSize" = "GigaByte" },
@{ "channel" = "total snapshots size"; "value" = [string]$v_spc.snapshots; "unit" = "BytesDisk"; "VolumeSize" = "GigaByte" },
@{ "channel" = "total volume size"; "value" = [string]$v_spc.volumes; "unit" = "BytesDisk"; "VolumeSize" = "GigaByte" }

$sensOut = ConvertTo-Json -InputObject $prtgSens -Depth 3

Write-Host @"
$sensOut
"@
