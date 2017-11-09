<#

.SYNOPSIS

Simple PRTG custom sensor for Pure Storage FlashArrays hardware components monitoring.

.DESCRIPTION

This custom sensor script retrieves the hardware components status from a Pure Storage FlashArray and returns them as seven channels in PRTG JSON format.
The script uses the PureStorage PowerShell SDK that must be installed on the probing host.

.PARAMETER EndPoint

A single computer name of a FlashArray. You may also provide the IP address.


.PARAMETER ApiToken


The API authentication token for the target FlashArray. 


.EXAMPLE


PRTG_PureFA-Volume.ps1 -EndPoint 172.16.0.12 -ApiToken cef628f0-831b-30b9-4494-4e8ea56c207c

#>


Param (
   [Parameter(Mandatory=$True,Position=1)]
   [string]$endpoint,
   [Parameter(Mandatory=$True,Position=2)]
   [string]$apitoken
)

$FA = New-PfaArray -EndPoint $endpoint -ApiToken $apitoken -IgnoreCertificateError

$hwattrs = Get-PfaAllHardwareAttributes -Array $FA
Disconnect-PfaArray -Array $FA

$bays = @()
$nvbs = @()
$pwrs = @()
$hwattrs | foreach {
    if ($_.name -like "*BAY*") {
        $bays += $_
    } elseif ($_.name -like "*NVB*") {
        $nvbs += $_
    } elseif ($_.name -like "*PWR*") {
        $pwrs += $_
    }
}

$bays = $bays | Sort-Object -Property index

foreach ($b in $bays ) {
    if ($b.status.equals('ok')) {
        $b.status = 100
    } else {
        $b.status = 0
    }
} 

$nvbs = $nvbs | Sort-Object -Property index
foreach ($n in $nvbs ) {
    if ($n.status.equals('ok')) {
        $n.status = 100
    } else {
        $n.status = 0
    }
}

$pwrs = $pwrs | Sort-Object -Property index
foreach ($p in $pwrs ) {
    if ($p.status.equals('ok')) {
        $p.status = 100
    } else {
        $p.status = 0
    }
}

$prtgSens = @{}
$prtgSens.prtg = @{}
$prtgSens.prtg.result = @()

foreach ($b in $bays) {
    $prtgSens.prtg.result += @{ "channel" = [string]$b.name; "value" = [string]$b.status; "unit" = "percent" }
}

foreach ($n in $nvbs ) {
    $prtgSens.prtg.result += @{ "channel" = [string]$n.name; "value" = [string]$n.status; "unit" = "percent" }
}

foreach ($p in $pwrs ) {
    $prtgSens.prtg.result += @{ "channel" = [string]$p.name; "value" = [string]$p.status; "unit" = "percent" }
}

$sensOut = ConvertTo-Json -InputObject $prtgSens -Depth 3

Write-Host @"
$sensOut
"@
