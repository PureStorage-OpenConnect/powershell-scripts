#region Remove-PfaRestSession
<#
    .SYNOPSIS
      Disconnects a FlashArray REST session
    .DESCRIPTION
      Takes in a FlashArray Connection or session and disconnects on the FlashArray.
    .INPUTS
      FlashArray connection or session
    .OUTPUTS
      Returns success or failure.
    .NOTES
      Version:        2.0
      Author:         Cody Hosterman https://codyhosterman.com
      Creation Date:  08/24/2020
      Purpose/Change: Core support
    .EXAMPLE
      PS C:\ $restSession | Remove-PfaRestSession -flasharray $fa

      Disconnects a direct REST session to a FlashArray. Does not disconnect the PowerShell session.
    *******Disclaimer:******************************************************
    This scripts are offered "as is" with no warranty.  While this
    scripts is tested and working in my environment, it is recommended that you test
    this script in a test lab before using in a production environment. Everyone can
    use the scripts/commands provided here without any written permission but I
    will not be liable for any damage or loss to the system.
    ************************************************************************
    #>

[CmdletBinding()]
Param(
    [Parameter(Position = 0, ValueFromPipeline = $True, mandatory = $true)]
    [Microsoft.PowerShell.Commands.WebRequestSession]$FaSession,

    [Parameter(Position = 1, ValueFromPipeline = $True, mandatory = $true)]
    [PurePowerShell.PureArray]$Flasharray
)
if ($null -eq $flasharray) {
    $flasharray = checkDefaultFlashArray
}
$purevip = $flasharray.endpoint
$apiVersion = $flasharray.ApiVersion
#Delete FA session
if ($PSVersionTable.PSEdition -ne "Core") {
    Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object IDontCarePolicy
    Invoke-RestMethod -Method Delete -Uri "https://${purevip}/api/${apiVersion}/auth/session" -WebSession $faSession -ErrorAction Stop | Out-Null
}
else {
    Invoke-RestMethod -Method Delete -Uri "https://${purevip}/api/${apiVersion}/auth/session" -WebSession $faSession -ErrorAction Stop -SkipCertificateCheck | Out-Null
}

#endregion