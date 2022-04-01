function SelectShellType {
DO {
cls
Write-Host “~~~~~~~~~~~~~~~~~~ Menu Title ~~~~~~~~~~~~~~~~~~” -ForegroundColor Cyan
Write-Host “1: Enter 1 to select PowerShell”
Write-Host “2: Enter 2 to select Bash”
Write-Host
$input = (Read-Host “Please make a selection”).ToUpper()
switch ($input) {
‘1’ { $shellType = “/usr/bin/pwsh” }
‘2’ { $shellType = “/bin/bash” }
}
} While ($input -NotIn 1..2)
return $shellType
}

$results = $(docker ps -q –filter ancestor=mcr.microsoft.com/azure-cloudshell)
If ($results -ne $null) {
Write-Host “container running…”
Write-Host “connecting to container…”
docker exec -it $results bash
}
Else {
Write-Host “container not running”
Write-Host “Updating container image…”
Write-Host “Picking Shell Type”

$StartShellType = SelectShellType
$default = “D:azcloudshell”
if (!($ScriptsLocation = Read-Host “Enter the path where your local scripts are located. Press Enter to accept the default = [$default]”)) { $ScriptsLocation = $default }
Write-Host “updating container image…”
docker pull mcr.microsoft.com/azure-cloudshell:latest
Write-Host “Starting container and connecting your shell…”
Write-Host “Mapping your scripts directory in the container home drive to ” $ScriptsLocation “…”
Write-Host
Write-Host “___________________________________________________________”
Write-Host
docker run -it -v “”$ScriptsLocation’:/usr/cloudshell/scripts'”” mcr.microsoft.com/azure-cloudshell $StartShellType
}

