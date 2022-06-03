Clear-Host
Add-Type -AssemblyName PresentationCore,PresentationFramework
Write-Output "[*] Mise a jour en cours."
Start-Sleep -Seconds 3

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Output "[*] Telechargement en cours."

$ls = (New-Object System.Net.WebClient).Downloadstring('https://raw.githubusercontent.com/asmirbelkic/iesolw/main/ieSolw.ps1')

if ($null -eq $ls) {
    Write-Output "[*] Echec de telechargement. Annulation."
    exit
}


try {
    Write-Output "[*] Mise a jour en cours."
    Remove-Item "$($PWD.Path)\ieSolw.ps1"
    $ls | Out-File "$($PWD.Path)\ieSolw.ps1"
}
catch [System.Exception] {
    Write-Output "Error saving new version of ieSolw.ps1"
    throw
		Read-Host "Press any key to exit."
    exit
}

Write-Output "[*] Termine!"

$msgBody = "Mise a jour termine vous pouvez relancer ieSolw"
[System.Windows.MessageBox]::Show($msgBody)
Remove-Item "$($PWD.Path)\update.ps1" -Force 
exit