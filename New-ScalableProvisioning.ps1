$FlashArray = Read-Host 'FlashArray IP/Name'
$EndPoint = New-PfaArray -EndPoint $FlashArray -Credentials (Get-Credential) -IgnoreCertificateError
$CustomerPrefix = Read-Host 'Customer Prefix'
$VolumeSize = Read-Host 'Volume Size (GB)'
$NumberOfVolumes = Read-Host 'Number of Volumes to create'

$Volumes = @()
for($i = 1; $i -le $NumberOfVolumes; $i++){
    New-PfaVolume -Array $EndPoint -VolumeName "$CustomerPrefix-Vol$i" -Unit G -Size $VolumeSize
    $Volumes += "$CustomerPrefix-Vol$i"

}
$Volumes -join ","

$AssigntoCustomerPGroup = Read-Host "Assign to $CustomerPrefix-PGroup (Y/N)"
if ($AssigntoCustomerPGroup.ToUpper() -eq 'Y') {
    New-PfaProtectionGroup -Array $EndPoint -Name "$CustomerPrefix-PGroup" -Volumes $Volumes
}
else {
    Write-Warning 'No Protection Group created.'
} 
