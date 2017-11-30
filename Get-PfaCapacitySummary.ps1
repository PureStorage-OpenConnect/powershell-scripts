# This is a sample script that surveys fleet of Pure flash arrays and outputs total capacity, written and provisioned figures.
# It's very easy to modify to send emails or write to tracking database 

$names = @(
"pfa-001.example.com"
"pfa-002.example.com"
# ... 
) # Populate this array with DNS names or IP addresses of your Pure arrays

$cred = Import-CliXml c:\PS\cred.xml # This is the connection credential. Write to file using "Get-Credential | Export-CliXml c:\PS\cred.xml". Must work across the fleet

$arrays = @()
foreach ($name in $names) { 
    try { $arrays += New-PfaArray -EndPoint $name -Credentials $cred -IgnoreCertificateError -Verbose -ErrorAction Stop }
    catch { echo "Error accessing $name : $_" }
}

$spacemetrix = $arrays | Get-PfaArraySpaceMetrics -Verbose
$spacemetrix = $spacemetrix | select *,@{N="expvolumes";E={$_.volumes*$_.data_reduction}},@{N="provisioned";E={$_.total/(1-$_.thin_provisioning)*$_.data_reduction}}

$totalcapacity = ($spacemetrix | measure capacity -sum).Sum
$totalvolumes = ($spacemetrix | measure volumes -sum).Sum
$totalvolumes_beforereduction = ($spacemetrix | measure expvolumes -sum).Sum
$totalprovisioned = ($spacemetrix | measure provisioned -sum).Sum

$1TB = 1024*1024*1024*1024

"On $($spacemetrix.Count) Pure arrays we have $([int]($totalcapacity/$1TB)) TB of capacity; $([int]($totalvolumes/$1TB)) TB written, which is reduced from $([int]($totalvolumes_beforereduction/$1TB)) TB. Total provisioned: $([int]($totalprovisioned/$1TB)) TB. Data collected on $(Get-Date)"