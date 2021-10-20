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
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

function Update-UserPassword {
    
    Param (  
    
    [Parameter(Mandatory = $true)][String]$User,
    [Parameter(Mandatory = $true)][String]$OldPassword,
    [Parameter(Mandatory = $true)][String]$NewPassword,
    [Parameter(Mandatory=$True)][Object[]]$Array
)

##################################################################
# This function expects a connection to have already been made
# to the target array using the Pure PowerShell SDK v1. That
# array object must be passed to this function, as we use that
# to obtain endpoint and API token information
##################################################################

$baseURI = "https://" + $Array.EndPoint + "/api/1.17"

##################################################################
# Establish Connection Using API Token from SDK1 Array Variable
##################################################################
$connectURI = $baseURI + "/auth/session"
$connectBody = @{
    api_token = $fa.ApiToken
}
$result = Invoke-WebRequest -Uri $connectURI -Method Post -Body $connectBody -SessionVariable pure -UseBasicParsing

##################################################################
# Update Password
##################################################################
$adminURI = $baseURI + "/admin/" + $User
$body = @{
    password = $NewPassword;
    old_password = $OldPassword;
}
$body = $body | convertto-json
$result = Invoke-WebRequest -Uri $adminURI -WebSession $pure -Method Put -Body $body -ContentType 'application/json' -UseBasicParsing

##################################################################
# Get and Return Updated User
##################################################################

$user=Invoke-WebRequest -uri $adminURI -Method Get -WebSession $pure -UseBasicParsing
return ConvertFrom-Json($user)
}

##################################################################
# Example Usage of the Update-UserPassword Function
##################################################################

$fa = New-PfaArray -EndPoint $my_array_IP -Credentials (Get-Credential) -IgnoreCertificateError
Update-UserPassword -Array $fa -User "jpctest" -OldPassword 'myoldpassword' -NewPassword 'mynewpassword'

