#region New-PfaRestSession
     <#
    .SYNOPSIS
      Connects to FlashArray and creates a REST connection.
    .DESCRIPTION
      For operations that are in the FlashArray REST, but not in the Pure Storage PowerShell SDK yet, this provides a connection for invoke-restmethod to use.
    .INPUTS
      FlashArray connection or FlashArray IP/FQDN and credentials
    .OUTPUTS
      Returns REST session
    .NOTES
      Version:        2.0
      Author:         Cody Hosterman https://codyhosterman.com
      Creation Date:  08/24/2020
      Purpose/Change: Core support
    .EXAMPLE
      PS C:\ $faCreds = get-credential
      PS C:\ $fa = New-PfaConnection -endpoint flasharray-m20-2 -credentials $faCreds -defaultArray
      PS C:\ $restSession = New-PfaRestSession -flasharray $fa

      Creates a direct REST session to the FlashArray for REST operations that are not supported by the PowerShell SDK yet. Returns it and also stores it in $global:faRestSession
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
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [PurePowerShell.PureArray]$Flasharray
    )
    #Connect to FlashArray
    if ($null -eq $flasharray)
    {
        $flasharray = checkDefaultFlashArray
    }
    if ($PSEdition -ne 'Core'){
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
  #Create FA REST session
    $SessionAction = @{
        api_token = $flasharray.ApiToken
    }
    Invoke-RestMethod -Method Post -Uri "https://$($flasharray.Endpoint)/api/$($flasharray.apiversion)/auth/session" -Body $SessionAction -SessionVariable Session -ErrorAction Stop |Out-Null
  }
  else {
    $SessionAction = @{
      api_token = $flasharray.ApiToken
  }
    Invoke-RestMethod -Method Post -Uri "https://$($flasharray.Endpoint)/api/$($flasharray.apiversion)/auth/session" -Body $SessionAction -SessionVariable Session -ErrorAction Stop -SkipCertificateCheck |Out-Null
  }
    $global:faRestSession = $Session
    return $global:faRestSession

#endregion
<# Invoke-RestMethod
 $Body = @{
     snap = "true"
     source = [Object[]]"$SnapshotVolume"
     suffix = $SnapshotSuffix"
 }
 $Params = @{
    Method = "Post"
    Uri = "https://$($flasharray.EndPoint)/api/$(flasharray.apiversion)/volume"
    Body = ($Body | ConvertTo-Json)
    WebSession = $Session
    ContentType = "application/json"
    ErrorAction = Stop
    -SkipCertificateCheck
}
Invoke-RestMethod @Params
#>