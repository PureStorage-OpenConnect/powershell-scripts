<#

.SYNOPSIS

Simple PRTG custom sensor for Pure Storage FlashArrays monitoring.

.DESCRIPTION

This custom sensor script retrieves the basic statistic counters from a Pure Storage FlashArray and returns them as seven channels in PRTG JSON format.
The script uses the PureStorage PowerShell SDK that must be installed on the probing host.

.PARAMETER EndPoint

A single computer name of a FlashArray. You may also provide the IP address.


.PARAMETER ApiToken


The API authentication token for the target FlashArray. 


.EXAMPLE


Pure-FA -EndPoint 172.16.0.12 -ApiToken cef628f0-831b-30b9-4494-4e8ea56c207c

#>


Param (
   [Parameter(Mandatory=$True,Position=1)]
   [string]$endpoint,
   [Parameter(Mandatory=$True,Position=2)]
   [string]$apitoken
)

$FA = New-PfaArray -EndPoint $endpoint -ApiToken $apitoken -IgnoreCertificateError

$iom = Get-PfaArrayIOMetrics -Array $FA

$prtgSens = @{}
$prtgSens.prtg = @{}
$prtgSens.prtg.result = @( 

@{ "channel" = "wr sec"; "value" = [string]$iom.writes_per_sec; "unit" = "custom"; "customunit" = "IOPS write" } ,
@{ "channel" = "rd sec"; "value" = [string]$iom.reads_per_sec; "unit" = "custom"; "customunit" = "IOPS read" } , 
@{ "channel" = "wr latency"; "value" = [string]$iom.usec_per_write_op; "unit" = "custom"; "customunit" = "usec" } ,
@{ "channel" = "rd latency"; "value" = [string]$iom.usec_per_read_op; "unit" = "custom"; "customunit" = "usec" } ,
@{ "channel" = "out sec"; "value" = [string]$iom.output_per_sec; "unit" = "BytesBandwidth"; "SpeedSize" = "Byte" } ,
@{ "channel" = "in sec"; "value" = [string]$iom.input_per_sec; "unit" = "BytesBandwidth"; "SpeedSize" = "Byte" } ,
@{ "channel" = "q depth"; "value" = [string]$iom.queue_depth; "unit" = "custom"; "customunit" = "avg queued" })

$sensOut = ConvertTo-Json -InputObject $prtgSens -Depth 3

Write-Host @"
$sensOut
"@