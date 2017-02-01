Clear-Host
$return = Read-Host -Prompt 'Enter the FQDN/IP to the Pure Storage FlashArray'
$user = Read-Host -Prompt 'Username'
$pwd = Read-Host -Prompt 'Password' -AsSecureString
$pattern = Read-Host -Prompt 'Enter Snapshot pattern to destroy and eradicate (Eg. VSS-)'
$timeframe = Read-Host -Prompt 'Enter Snapshot retention period in minutes (Eg. 2hr = 120)'

$FlashArray = New-PfaArray -EndPoint $return -Username $user -Password $pwd -IgnoreCertificateError
$Initiators = Get-PfaHosts -Array $FlashArray

$destroy = @()

Write-Host '============================'
Write-Host "Hosts on $return"
Write-Host '============================'

# Determine current FlashArray time.
$tempvol = [GUID]::NewGuid()
New-PfaVolume -Array $FlashArray -VolumeName $tempvol -Unit M -Size 1 | Out-Null
$array = Get-PfAvolume -Array $FlashArray -Name $tempvol
Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $tempvol | Out-Null
Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $tempvol -Eradicate | Out-Null

ForEach ($Initiator in $Initiators)
{
  Write-Host "  [H] $($Initiator.name)"

  $Volumes = Get-PfaHostVolumeConnections -Array $FlashArray -Name $Initiator.name
  If (!$Volumes)
  {
    Write-Host '   |   |----[No volumes connected]'        
  }
  Else
  {
    ForEach ($Volume in $Volumes)
    {
      Write-Host "   |   |----[V] $($Volume.vol)"
    
      $Snapshots = Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $Volume.vol
      ForEach ($Snapshot in $Snapshots)
      {
        If (($Snapshot.name) -like "*$pattern*")
        {
          # Based on US datetime format.
          $TimeSpan = New-TimeSpan -Start ([datetime]$Snapshot.created) -End ([datetime]$array.created)
          Write-Host ">  |   |       |----[$pattern] $($Snapshot.name)"
          If($TimeSpan.Minutes -ge $timeframe)
          {
            $destroy += $Snapshot.name        
          }
        }
        Else
        {
          Write-Host "   |   |       |----[S] $($Snapshot.name)"
        }
      }
    }
  }
}

$voldestroylist = @($null)
ForEach ($vol in $destroy)
{
  $voldestroylist += "$vol`r`n"
}
$destroy_retval = Read-Host -Prompt "`r`n`r`nDo you want to DESTROY $($voldestroylist.Count) snapshot(s) [Y/N]?"
If ($destroy_retval.ToUpper() -eq 'Y')
{
  ForEach ($voldestroy_item in $voldestroylist) 
  {
    #Only destroy volume. To add eradicate functionality add -Eradicate parameter.
    #
    #Uncomment below line for destroy to work.
    #Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $voldestroy_item -ErrorAction SilentlyContinue | Out-Null
  }
}

Disconnect-PfaArray -Array $FlashArray

# SIG # Begin signature block
# MIINIQYJKoZIhvcNAQcCoIINEjCCDQ4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUX72+bnETEssSpFaALZPTWpl6
# nFOgggpjMIIFKzCCBBOgAwIBAgIQCamgNd9B0v6RJ4iA0KHDFDANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE2MDQyMzAwMDAwMFoXDTE3MDQy
# NzEyMDAwMFowaDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFDAS
# BgNVBAcTC1NhbnRhIENsYXJhMRYwFAYDVQQKEw1Sb2JlcnQgQmFya2VyMRYwFAYD
# VQQDEw1Sb2JlcnQgQmFya2VyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAr1I0EO2uOScoPi9giUITw4CH1qT2MJsPqG4pHhndW2M12EBl4HcDVi/cOZG+
# EZHduaKFSXy6nR0BuPbNB76/NODdS0id2Q7ppWbtld74O/OmtLn6SAW6qjKeYas7
# N4xUV6pK62yzGGBG/gr9CS97kzaW6mwR803MmTwTVa9QofV3DioppJM7eTWSmPHU
# fyGVAE1LjnlYlgKPcAGGmtseXKwQjyXq8wCvlnUOPiHZp/cXPpJzYq6krehZnnEq
# NLALQROtBEqnKXGFEQH8U0Qc7pqugO+0lhnbV9/XLwIauyjLqNyJ+p7lZ8ZElS17
# j9PjQuJ+hyXotzPL1WIod9ghXwIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5
# eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYEFJQeLmdYk4a/RXLk2t9XUgabNd/R
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBu
# MDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNz
# LWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNz
# dXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggrBgEF
# BQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEwgYQG
# CCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tME4GCCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIw
# ADANBgkqhkiG9w0BAQsFAAOCAQEAK7mB6k0XrieW8Fgc1PE8QmQWhXieDu1TKWAl
# tSgXopddqUyLCdeqMoPj6otYYdnLNf9VGjxCWnZj1qXBrgyYv1FuWgwDhfL/xmZ0
# 9uKx9yIjx45HFU1Pw3sQSQHO+Q0pp652T7V7pfs9wcsqzUZJpdCRXtWAPpGuYyW+
# oX3jai6Mco/DrdP6G7WPMnlc/5yV7Y824yXsJKoX/qENgtbctZeQ4htx4aaT3Pg7
# 9ppUunl754w8MDAVTQUVrKGH3TDwsBTRjsGb7on+QldBJzOsrE2Pq9P4fnIYdqO7
# 4JQ5YpUHn2p1pLXSukWchNgIeix/yCdjn78jL/RvpsJoSPdKfzCCBTAwggQYoAMC
# AQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEz
# MTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP
# 0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6
# funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQt
# oaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ry
# CuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKW
# wfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9EC
# AwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGG
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0
# MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYw
# OAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2Vy
# dC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32
# ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0B
# AQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v9
# 7yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZO
# XP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+b
# p1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd
# 6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92Ju
# oVP6EpQYhS6SkepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2Rl
# IFNpZ25pbmcgQ0ECEAmpoDXfQdL+kSeIgNChwxQwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFeb
# Dyic2EaJB6aCvnVgBIemKx+XMA0GCSqGSIb3DQEBAQUABIIBAGkJbYU0wViH7ZRM
# lLPsk5TrrK7Sg/VVq6H+eSRurZzGtH6+k3v5puRio34v9wf5rZMsFy9zyCUrAxPj
# r60kNyjDAjq5qZiLoyDZu0IeSiOIT5cwjK5ueZgGDhM2tTlJ8Vd50VsKbtrc8C+G
# aUkmgEujIZndCdc0ovfFSxramGDlG6flw5wHixtmbSOTa63owSHO5KC8CLg6IlDy
# 608lg69wybevFtANoawp1noCmKjC70/UzEb4jtpSbJ2l61fbVOz8efQRPvjNgLlS
# eFj6+A/Df0QWEpsEpfKqlSprQYBIgoDTj0hVw6EQYmgFRUG2J8o1joR3lVXr1N7k
# G44/Ets=
# SIG # End signature block
