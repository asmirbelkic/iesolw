$Logfile = "$env:TEMP\CitrixReplacer.log.txt"

Function LogWrite
{
	Param ([string]$logstring)
	
	Add-content $Logfile -value "$((Get-Date).ToString()) $logstring"
}

function Get-FileFromWeb
{
	param (
		# Parameter help description
		[Parameter(Mandatory)]
		[string]$URL,
		# Parameter help description
		[Parameter(Mandatory)]
		[string]$File
	)
	Begin
	{
		function Show-Progress
		{
			param (
				# Enter total value
				[Parameter(Mandatory)]
				[Single]$TotalValue,
				# Enter current value
				[Parameter(Mandatory)]
				[Single]$CurrentValue,
				# Enter custom progresstext
				[Parameter(Mandatory)]
				[string]$ProgressText,
				# Enter value suffix
				[Parameter()]
				[string]$ValueSuffix,
				# Enter bar lengh suffix
				[Parameter()]
				[int]$BarSize = 40,
				# show complete bar
				[Parameter()]
				[switch]$Complete
			)
			
			# calc %
			$percent = $CurrentValue / $TotalValue
			$percentComplete = $percent * 100
			if ($ValueSuffix)
			{
				$ValueSuffix = " $ValueSuffix" # add space in front
			}
			if ($psISE)
			{
				Write-Progress "$ProgressText $CurrentValue$ValueSuffix of $TotalValue$ValueSuffix" -id 0 -percentComplete $percentComplete
			}
			else
			{
				# build progressbar with string function
				$curBarSize = $BarSize * $percent
				$progbar = ""
				$progbar = $progbar.PadRight($curBarSize, [char]9608)
				$progbar = $progbar.PadRight($BarSize, [char]9617)
				
				if (!$Complete.IsPresent)
				{
					Write-Host -NoNewLine "`r$ProgressText $progbar [ $($CurrentValue.ToString("#.###").PadLeft($TotalValue.ToString("#.###").Length))$ValueSuffix / $($TotalValue.ToString("#.###"))$ValueSuffix ] $($percentComplete.ToString("##0.00").PadLeft(6)) % complete"
				}
				else
				{
					Write-Host -NoNewLine "`r$ProgressText $progbar [ $($TotalValue.ToString("#.###").PadLeft($TotalValue.ToString("#.###").Length))$ValueSuffix / $($TotalValue.ToString("#.###"))$ValueSuffix ] $($percentComplete.ToString("##0.00").PadLeft(6)) % complete"
				}
			}
		}
	}
	Process
	{
		try
		{
			$storeEAP = $ErrorActionPreference
			$ErrorActionPreference = 'Stop'
			
			# invoke request
			$request = [System.Net.HttpWebRequest]::Create($URL)
			$response = $request.GetResponse()
			
			if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404)
			{
				throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$URL'."
			}
			
			if ($File -match '^\.\\')
			{
				$File = Join-Path (Get-Location -PSProvider "FileSystem") ($File -Split '^\.')[1]
			}
			
			if ($File -and !(Split-Path $File))
			{
				$File = Join-Path (Get-Location -PSProvider "FileSystem") $File
			}
			
			if ($File)
			{
				$fileDirectory = $([System.IO.Path]::GetDirectoryName($File))
				if (!(Test-Path($fileDirectory)))
				{
					[System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null
				}
			}
			
			[long]$fullSize = $response.ContentLength
			$fullSizeMB = $fullSize / 1024 / 1024
			
			# define buffer
			[byte[]]$buffer = new-object byte[] 1048576
			[long]$total = [long]$count = 0
			
			# create reader / writer
			$reader = $response.GetResponseStream()
			$writer = new-object System.IO.FileStream $File, "Create"
			
			# start download
			$finalBarCount = 0 #show final bar only one time
			do
			{
				
				$count = $reader.Read($buffer, 0, $buffer.Length)
				
				$writer.Write($buffer, 0, $count)
				
				$total += $count
				$totalMB = $total / 1024 / 1024
				
				if ($fullSize -gt 0)
				{
					Show-Progress -TotalValue $fullSizeMB -CurrentValue $totalMB -ProgressText "Downloading $($File.Name)" -ValueSuffix "MB"
				}
				
				if ($total -eq $fullSize -and $count -eq 0 -and $finalBarCount -eq 0)
				{
					Show-Progress -TotalValue $fullSizeMB -CurrentValue $totalMB -ProgressText "Downloading $($File.Name)" -ValueSuffix "MB" -Complete
					$finalBarCount++
					#Write-Host "$finalBarCount"
				}
				
			}
			while ($count -gt 0)
		}
		
		catch
		{
			
			$ExeptionMsg = $_.Exception.Message
			Write-Host "Download breaks with error : $ExeptionMsg"
		}
		
		finally
		{
			# cleanup
			if ($reader) { $reader.Close() }
			if ($writer) { $writer.Flush(); $writer.Close() }
			
			$ErrorActionPreference = $storeEAP
			[GC]::Collect()
		}
	}
}

function Get-InstalledApps
{
	if ([IntPtr]::Size -eq 4)
	{
		$regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
	}
	else
	{
		$regpath = @(
			'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
			'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
		)
	}
	Get-ItemProperty $regpath | .{process { if ($_.DisplayName -and $_.UninstallString) { $_ } } } | Select DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString | Sort DisplayName
}

LogWrite "Script started !"
Write-Output "Script v1.0.0 by Asmir SOLWARE AUTO - Citrix 2205 Installer."
$url = "https://www.dropbox.com/s/nuaril2sz1sjyjd/CitrixWorkspaceApp.exe?dl=1"
$output = "$env:userprofile\downloads\CitrixWorkspaceApp.exe"

if (Test-Path -Path $output -PathType leaf)
{
	if ((Get-Item $output).VersionInfo.ProductVersion -ne "22.5.0")
	{
		Remove-Item $output -Force
		Write-Output "Downloading Citrix 2205"
		Get-FileFromWeb $url $output
		LogWrite "Downloaded $output"
	}
}
else
{
	Write-Output "Downloading Citrix 2205"
	Get-FileFromWeb $url $output
	LogWrite "Downloaded $output"
}

$CitrixUpdt = Get-Process "CitrixReceiverUpdater" -ErrorAction SilentlyContinue
if ($CitrixUpdt)
{
	$CitrixUpdt.CloseMainWindow()
	Sleep 5
	if (!$CitrixUpdt.HasExited)
	{
		$CitrixUpdt | Stop-Process -Force
	}
	LogWrite "Process CitrixReceiverUpdater killed"
}
Remove-Variable CitrixUpdt

$result = Get-InstalledApps | where { $_.Publisher -like "Citrix Systems, Inc." }
If (-Not $result)
{
    LogWrite "Citrix not found, installing."
    Write-Output "OK, installing."
	Start-Process $output -Verb runAs -ArgumentList '/AutoUpdateCheck=disabled' -Wait
	Write-Output "OK end."
	LogWrite "Install end OK !"
	sleep 1
	exit
}
else
{
	try
	{
		LogWrite "Uninstall start..."
		Write-Output "`nUninstalling."
		Start-Process $output -Verb runAs -ArgumentList '/uninstall' -Wait
		LogWrite "Uninstall end OK !"
	}
	catch
	{
		Write-Output "`nError Message: " $_.Exception.Message
		LogWrite "Error $_.Exception.Message"
	}
	finally
	{
		Write-Output "OK, installing."
		LogWrite "Install start..."
		$proc = Start-Process $output -ArgumentList '/AutoUpdateCheck=disabled' -NoNewWindow -PassThru
		$proc.WaitForExit()
		Write-Output "OK end."
		LogWrite "Install end OK !"
		LogWrite "Finished closing script..."
		sleep 1
		exit
	}
}