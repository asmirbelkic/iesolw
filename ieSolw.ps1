Add-Type -AssemblyName PresentationCore,PresentationFramework
Clear-Host
$version = "1.0"
$githubver = "https://raw.githubusercontent.com/asmirbelkic/iesolw/main/currentversion.txt"
$updatefile = "https://raw.githubusercontent.com/asmirbelkic/iesolw/main/update.ps1"

function UpdatesAvailable()
{
	$updateavailable = $false
	$nextversion = $null
	try
	{
		$nextversion = (New-Object System.Net.WebClient).DownloadString($githubver).Trim([Environment]::NewLine)
	}
	catch [System.Exception] 
	{
		Write-Host $_
	}
	
	Write-Host "Version actuelle: $version"
	Write-Host "Nouvelle version: $nextversion"
	if ($nextversion -ne $null -and $version -ne $nextversion)
	{
		#An update is most likely available, but make sure
		$updateavailable = $false
		$curr = $version.Split('.')
		$next = $nextversion.Split('.')
		for($i=0; $i -le ($curr.Count -1); $i++)
		{
			if ([int]$next[$i] -gt [int]$curr[$i])
			{
				$updateavailable = $true
				break
			}
		}
	}
	return $updateavailable
}

function processUpdate() {
	if (Test-Connection 8.8.8.8 -Count 1 -Quiet) {
		$updatepath = "$($PWD.Path)\update.ps1"
		if (Test-Path -Path $updatepath)	
		{
			#Remove-Item $updatepath
		}
		if (UpdatesAvailable)
		{
			$msgBody = "Une mise a jour est disponible, voulez vous mettre a jour IESolw ?"
			$msgTitle = "Mise a jour"
			$msgButton = 'YesNo'
			$msgImage = 'Question'
			$result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)
			if ($result -eq 'Yes')
			{	
				(New-Object System.Net.Webclient).DownloadFile($updatefile, $updatepath)
				Start-Process PowerShell -Arg $updatepath -NoNewWindow
				exit
			}
		}
	}
	else
	{
		Write-Message "Unable to check for updates. Internet connection not available."
	}
}

ProcessUpdate
