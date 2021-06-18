<#
.SYNOPSIS
Script to disable Nagle (TcpNoDelay) and TcpAckFrequency on a per adapter basis.
.DESCRIPTION
This script will enumerate all of the adapters in a server and require the user to enter the names of each that they wish to have the following registry changes made for:
HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$adapterGuid\TcpAckFrequency set to a value of "1" (disabled)
HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$adapterGuid\TcpNoDelay set to a value of  "1" (disabled)
.EXAMPLE
Set-IscsiTcpSettings

.NOTES
Backup the registry before running this script. You have been warned!
Tested on Server 2016, 2019, and 2022 Preview. Use on older versions at your own risk.
This script should be tested in a non-production environment before implementing in production.

Disclaimer
    The sample module and documentation are provided AS IS and are not supported by
	the author or the author’s employer, unless otherwise agreed in writing. You bear
	all risk relating to the use or performance of the sample script and documentation.
	The author and the author’s employer disclaim all express or implied warranties
	(including, without limitation, any warranties of merchantability, title, infringement
	or fitness for a particular purpose). In no event shall the author, the author’s employer
	or anyone else involved in the creation, production, or delivery of the scripts be liable
	for any damages whatsoever arising out of the use or performance of the sample script and
	documentation (including, without limitation, damages for loss of business profits,
	business interruption, loss of business information, or other pecuniary loss), even if
	such person has been advised of the possibility of such damages.
#>

        Write-Host ''
        Write-Host 'Checking iSCSI Settings...'
        Write-Host ''

        $AdapterNames = @()
        Write-Host "All available adapters: "
        Write-Host " "
        $adapters = Get-NetAdapter | Sort-Object Name | Format-Table -Property "Name", "InterfaceDescription", "MacAddress", "Status"
        $adapters
        Write-Host " "
        $AdapterNames = Read-Host "Please enter all iSCSI adapter names to be tested. Use a comma to seperate the names - ie. NIC1,NIC2,NIC3"
        $AdapterNames = $AdapterNames.Split(',')
        Write-Host " "
        Write-Host "Adapter names being configured: "
        $AdapterNames
        Write-Host "==============================="
        foreach ($adapter in $AdapterNames) {
            $adapterGuid = (Get-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword "NetCfgInstanceId" -AllProperties).RegistryValue
            $RegKeyPath = "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$adapterGuid\"
            $TAFRegKey = "TcpAckFrequency"
            $TNDRegKey = "TcpNoDelay"
            ## TcpAckFrequency
            if ((Get-ItemProperty $RegkeyPath).$TAFRegKey -eq "1") {
                Write-Host ": TcpAckFrequency is set to disabled (1). No action required."
            }
            if (-not (Get-ItemProperty $RegkeyPath $TAFRegKey -ErrorAction SilentlyContinue)) {
                Write-Host ": TcpAckFrequency key does not exist."
                Write-Host "REQUIRED ACTION: Set the TcpAckFrequency registry value to 1 for $adapter ?" -NoNewline
                $resp = Read-Host -Prompt "Y/N?"
                if ($resp.ToUpper() -eq 'Y') {
                    Write-Host "Creating Registry key and setting to disabled..."
                    New-ItemProperty -Path $RegKeyPath -Name 'TcpAckFrequency' -Value '1' -PropertyType DWORD -Force -ErrorAction SilentlyContinue
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": TcpAckFrequency registry key exists but is enabled. Changing to disabled."
                    Set-ItemProperty -Path $RegKeyPath -Name 'TcpAckFrequency' -Value '1' -Type DWORD -Force -ErrorAction SilentlyContinue
                }
            }
            if ($resp.ToUpper() -eq 'N') {
                Write-Host "ABORTED" -ForegroundColor Yellow -NoNewline
                Write-Host ": Registry key not created or altered by request of user."

            }
            ## TcpNoDelay
            if ((Get-ItemProperty $RegkeyPath).$TNDRegKey -eq "1") {
                Write-Host ": TcpNoDelay (Nagle) is set to disabled (1). No action required."
            }
            if (-not (Get-ItemProperty $RegkeyPath $TNDRegKey -ErrorAction SilentlyContinue)) {
                Write-Host "REQUIRED ACTION: Set the TcpNodelay (Nagle) registry value to 1 for $adapter ?" -NoNewline
                $resp = Read-Host -Prompt "Y/N?"
                if ($resp.ToUpper() -eq 'Y') {
                    Write-Host "TcpNoDelay registry key does not exist. Creating..."
                    New-ItemProperty -Path $RegKeyPath -Name 'TcpNoDelay' -Value '1' -PropertyType DWORD -Force -ErrorAction SilentlyContinue
                }
                else {
                    Write-Host "WARNING" -ForegroundColor Yellow -NoNewline
                    Write-Host ": TcpNoDelay registry key exists. Setting value to 1."
                    Set-ItemProperty -Path $RegKeyPath -Name 'TcpNoDelay' -Value '1' -Type DWORD -Force -ErrorAction SilentlyContinue
                }
            }
            if ($resp.ToUpper() -eq 'N') {
                Write-Host "ABORTED" -ForegroundColor Yellow -NoNewline
                Write-Host ": TcpNoDelay registry key not created or altered by request of user."
            }
        }
# END