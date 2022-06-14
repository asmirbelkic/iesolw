@Echo Off
@setlocal DisableDelayedExpansion
goto SOL_Start

REM By Asmir BELKIC pour Solware AUTO ? 2022
REM Version 1.0.5-v5
REM Ouverture de ICM, DFM, Service BOX en mode compatibilite
REM Correction et amelioration du fonctionnement du script
REM Ajout d'options, questions lors de l'installation de la liste (remplacement de liste pre-existante).
REM Ajout du script de correction de l'erreur -2146828218 Permission refusee pour Servicebox.
REM Ajout d'un extra pour installer le certificat local *rootCA.crt* https://apisolware.dms.dcs2.renault.com
REM Mise en place d'un mise a jour automatique du script depuis github.
REM Fichier list.xml
REM Mise a jour le (09/04/2022)
REM Compatibles (s'ouvre avec IE11) = [*.renault.com/*, *.renault.fr/*, *.citroen.fr/*, *.mpsa.com*/, *.peugot.com/*, *.groupe-lacour.fr/*, *.inetpsa.com/*, *.athoris.net/*, *.salesforce.com/*, *.vectury.com/*]
REM Exclus (s'ouvre avec Edge Chromium) = [newdialogys.renault.com, ope2eu.ppx.ope2eu.asdh.aws.renault.com]
::========================================================================================================================================

REM Variables SET
:SOL_Start
set _elev=
if /i "%~1"=="-el" set _elev=1
set "_null=1>nul 2>nul"
set "_nul=1>nul 2>nul"
set "_psc=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "_batf=%~f0"
set "_batp=%_batf:'=''%"
set "version=1.4"
set githubver="https://raw.githubusercontent.com/asmirbelkic/intSolw/main/currentversion.txt"
set updatefile="https://raw.githubusercontent.com/asmirbelkic/intSolw/main/intSolw.cmd"
set githublist="https://raw.githubusercontent.com/asmirbelkic/intSolw/main/list.xml"
set "EchoRed=%_psc% write-host -BackgroundColor Black -ForegroundColor Red"
set "EchoYellow=%_psc% write-host -ForegroundColor Red -BackgroundColor Yellow"
set "EchoGreen=%_psc% write-host -BackgroundColor Black -ForegroundColor Green"
set "ListFile=%~dp0list.xml"
set "_dest=%USERPROFILE%\Solware"
set ServicesLIST=HTTPS_Connector Dfm.WebLocal.Service SACSrv SCardSvr
::========================================================================================================================================

REM  Eleves le script en mode administrateur

set "batf_=%~f0"
set "batp_=%batf_:'=''%"

%_null% reg query HKU\S-1-5-19 && (
goto :_Passed
) || (
if defined _elev goto :_E_Admin
)

set "_vbsf=%temp%\admin.vbs"
set _PSarg="""%~f0""" -el

setlocal EnableDelayedExpansion
(
echo Set strArg=WScript.Arguments.Named
echo Set strRdlproc = CreateObject^("WScript.Shell"^).Exec^("rundll32 kernel32,Sleep"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& strRdlproc.ProcessId ^& "'"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& .ParentProcessId ^& "'"^)
echo If InStr ^(.CommandLine, WScript.ScriptName^) ^<^> 0 Then
echo strLine = Mid^(.CommandLine, InStr^(.CommandLine , "/File:"^) + Len^(strArg^("File"^)^) + 8^)
echo End If
echo End With
echo .Terminate
echo End With
echo CreateObject^("Shell.Application"^).ShellExecute "cmd.exe", "/c " ^& chr^(34^) ^& chr^(34^) ^& strArg^("File"^) ^& chr^(34^) ^& strLine ^& chr^(34^), "", "runas", 1
)>"!_vbsf!"

(%_null% cscript //NoLogo "!_vbsf!" /File:"!batf_!" -el) && (
del /f /q "!_vbsf!"
exit /b
) || (
del /f /q "!_vbsf!"
%_null% %_psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && (
exit /b
) || (
goto :_E_Admin
)
)
exit /b

:_E_Admin
%ErrLine%
echo Ce script a besoin des privileges administrateur.
goto SOLClose

:_Passed
title intSolw - Mise a jour en cours...
setlocal DisableDelayedExpansion
set "output=%temp%\intSolw.tmp"
for /F "usebackq delims=" %%I in (`%_psc% "(New-Object System.Net.WebClient).DownloadString('%githubver%').Trim([Environment]::NewLine)"`) do set _nextversion=%%I
echo %version% %_nextversion%
if %version% NEQ %_nextversion% (
      echo [*] Recherche de mise a jour
      timeout /t 3 /nobreak >nul 2>&1
      echo [*] Telechargement
	  %_null% %_psc% "(New-Object System.Net.WebClient).DownloadFile('%updatefile%', '%output%')"
	  move /Y %output% %~dp0\intSolw.cmd >nul 2>&1
      echo [*] Mise a jour terminer, redemarrage.
      timeout /t 1 /nobreak >nul 2>&1
	  %0 
)
::========================================================================================================================================

REM On creer ici notre dossier pour list.xml

if not exist "%_dest%" mkdir "%_dest%"

::========================================================================================================================================

REM Pour la coloration on demande powershell.exe

for %%i in (powershell.exe) do if "%%~$path:i"=="" (
echo: &echo Erreur &echo:
echo Powershell n'est pas install? dans le syst?me.
echo Abandon...
goto SOLClose
)

::========================================================================================================================================
setlocal EnableDelayedExpansion

REM Menu principal

:MainMenu
cls
title intSolw - Outil interne Solware - %version% by Asmir
REM On affiche le menu principal

if %version% EQU %_nextversion% (
%EchoGreen% v.%version%
) else (
%EchoRed% Veuillez relancer le script pour le mettre a jour.
echo Si vous rencontrez un probleme avec ce script, contactez moi abelkic@solware.fr ou par teams - Asmir Belkic
)
echo:
%EchoYellow% /^^!\ Merci de lire les informations disponibles dans [Info]
%EchoYellow% Ce script ne peut pas fonctionner avec une version de Windows inferieure a Windows 10.
echo:
echo 1 - Activer le mode compatibilite
echo 2 - Desactiver le mode compatibilite
echo 3 - [PSA] Permission Servicebox 
echo 4 - Autres
echo:
echo 5 - Info
echo 6 - Quitter
echo:
choice /C:123456 /M "Choisissez une option : "

REM On recupere le errorlevel du choix puis on renvoie vers la bonne fonction

if errorlevel 6 exit
if errorlevel 5 call:ReadMe faq & goto:MainMenu
if errorlevel 4 goto:Extras
if errorlevel 3 goto:paramIE
if errorlevel 2 call :UninstList & cls & goto :MainMenu
if errorlevel 1 call :InstallList & cls & goto :MainMenu

::========================================================================================================================================

REM Menu Extras

:Extras
setlocal enabledelayedexpansion
cls
title intSolw - Autres
echo Menu ^> Autres
echo:
echo 1 - Redemarrer les services
echo 2 - Nettoyer les fichiers temporaires + reinitialiser Internet Explorer
echo 3 - Patcher le fichier hosts
echo 4 - Activer TLS 1.2 / 1.1
echo 5 - Installer certificat - apisolware
echo 6 - Retour
echo:
choice /C:123456 /M "Choisissez une option : "

REM On recupere le errorlevel du choix puis on renvoie vers la bonne fonction

if errorlevel 6 goto :MainMenu
if errorlevel 5 setlocal & cls & call :InstallCert & endlocal & goto :Extras
if errorlevel 4 call :PatchTLS & goto :Extras
if errorlevel 3 setlocal & call :HostsPatch & cls & endlocal & goto :Extras
if errorlevel 2 call :Nettoyer & cls & goto :Extras
if errorlevel 1 call :RestartServices & cls & goto :Extras
::========================================================================================================================================

REM Installation de la liste

:InstallList
cls
title Installation de la liste

setlocal & call :COPYLIST & cls & endlocal

:COPYLIST

REM Verification des services

echo ================= Services =================
(for %%i in (%ServicesLIST%) do ( 
   sc query %%i >nul 2>&1
   if errorlevel 1060 %EchoRed% Service %%i : manquant
   (for /F "tokens=3 delims=: " %%H in ('sc query %%i^|find /i "STATE"') do (
    if /I "%%H" EQU "RUNNING" (
       echo Service %%i : En cours
    )
      if /I "%%H" EQU "STOPPED" (
       echo Service %%i : A l'arret
      )
    ))
))
echo ============================================ & echo.

REM On verifie SafeNet + On affiche la version de SafeNet
reg query "HKLM\SOFTWARE\SafeNet\Authentication\SAC" /v RevisionID >nul 2>&1
if %errorlevel% == 0 (
  for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\SafeNet\Authentication\SAC" /V RevisionID ^|findstr /ri "REG_SZ"') do echo Version SafeNet : %%a
) else (
  %EchoRed% SafeNet non installer
)

REM On check la version de RNFI Master KIT
reg query "HKLM\Software\Renault\Renault.Net Full Internet" /v Version_Master_RNFI >nul 2>&1
if %errorlevel% == 0 (
  for /f "tokens=3" %%a in ('reg query "HKLM\Software\Renault\Renault.Net Full Internet"  /V Version_Master_RNFI  ^|findstr /ri "REG_SZ"') do echo Version Renault.NET : %%a
) else (
  %EchoRed% Renault.NET non installer
)
goto ADD_REG

REM Maintenant on renvoie vers :ADD_REG

goto ADD_REG
pause >nul
goto:MainMenu
 
REM Ajout de la liste directement dans le registre

:ADD_REG
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DefaultBrowserSettingEnabled/t REG_DWORD /d 1 /f  >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v HideInternetExplorerRedirectUXForIncompatibleSitesEnabled /t REG_DWORD /d 1 /f  >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v RedirectSitesFromInternetExplorerRedirectMode /f  >nul 2>&1

REM On verifie RenaultNet
reg query "HKLM\Software\Renault\Renault.Net Full Internet" >nul 2>&1
IF %errorlevel% == 0 (
REM Chrome
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\AutoSelectCertificateForUrls" /v 1 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\AutoSelectCertificateForUrls" /v 2 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.fr/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\AutoSelectCertificateForUrls" /v 3 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.fr/*\",\"filter\":{}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\AutoSelectCertificateForUrls" /v 4 /t REG_SZ /d "{\"pattern\":\"https://[*.]alliance-rnm.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\AutoSelectCertificateForUrls" /v 5 /t REG_SZ /d "{\"pattern\":\"https://[*.]vectury.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1

REM Edge
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls" /v 1 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls" /v 2 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.fr/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls" /v 3 /t REG_SZ /d "{\"pattern\":\"https://[*.]renault.fr/*\",\"filter\":{}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls" /v 4 /t REG_SZ /d "{\"pattern\":\"https://[*.]alliance-rnm.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\AutoSelectCertificateForUrls" /v 5 /t REG_SZ /d "{\"pattern\":\"https://[*.]vectury.com/*\",\"filter\":{\"ISSUER\":{\"CN\":\"Class 2 Authentication CA\"}}}" /f >nul 2>&1
)

REM Ajouter la liste .xml dans le registre

reg add "HKCU\Software\Policies\Microsoft\Edge" /v InternetExplorerIntegrationLevel /t REG_DWORD /d 00000001 /f  >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NotifyDisableIEOptions /t REG_DWORD /d 00000001 /f  >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v InternetExplorerIntegrationSiteList /t REG_SZ /d "%githublist%" /f >nul 2>&1

REM Ne pas demander si un seul certif trouv?

reg add "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v 1A04 /t REG_DWORD /d 0  /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Lockdown_Zones\4" /v 1A04 /t REG_DWORD /d 0  /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v 1A04 /t REG_DWORD /d 0  /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Lockdown_Zones\4" /v 1A04 /t REG_DWORD /d 0  /f >nul 2>&1

REM Lancement puis redemarrage de Microsoft Edge (MSEDGE.EXE)

:LOOP
START "" "msedge.exe"
TASKLIST / FIND /I "msedge.exe" >nul 2>&1
IF ERRORLEVEL 0 (
  GOTO CONTINUE
) ELSE (
  echo Microsoft Edge est toujours en cours d'execution...
  TIMEOUT /T 5
  GOTO LOOP
)

REM Arret du processus MSEDGE.EXE

:CONTINUE
TIMEOUT /T 1 >nul
taskkill /f /im msedge.exe /t >nul 2>&1
%EchoGreen% Fini ^!

TIMEOUT /T 5
goto:MainMenu

::========================================================================================================================================

REM Desinsatllation et suppression de la liste

:UninstList
cls
title Suppression de la liste
echo Suppression en cours...
cls
reg delete "HKCU\Software\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode" /v Enable /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode" /v SiteList /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v InternetExplorerIntegrationLevel /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v RedirectSitesFromInternetExplorerRedirectMode /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v InternetExplorerIntegrationSiteList /f >nul 2>&1
del /f /q "%_dest%\list.xml"
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v RedirectSitesFromInternetExplorerRedirectMode /f  >nul 2>&1
cls
%EchoGreen% Suppression - OK !

TIMEOUT /T 5
goto:MainMenu
REM Del Success

::========================================================================================================================================

REM On force la mise a jour avec RunDll32.EXE InetCpl.cpl,ClearMyTracksByProcess 8

:Nettoyer
cls
title Mise a jour

taskkill /im iexplore.exe /f >nul 2>&1
taskkill /im msedge.exe /f >nul 2>&1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1 >nul 2>&1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8 >nul 2>&1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2048 >nul 2>&1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4096 >nul 2>&1
RunDll32.exe InetCpl.cpl,ResetIEtoDefaults >nul 2>&1
del %TEMP%\*.* /f /s /q >nul 2>&1
%EchoGreen% Suppression des fichiers locaux - OK
TIMEOUT /T 5
goto:Extras

::========================================================================================================================================

REM Patch du fichier hosts

:HostsPatch
cls
title Patch en cours

REM Vars
setlocal EnableDelayedExpansion
set _hosts=%WINDIR%\system32\drivers\etc\hosts
set _ipLocal=127.0.0.1

findstr /v /i /L /c:"apisolware.dms.dcs2.renault.com" %_hosts% > %_hosts%
if exist "C:\Winmotor\Soc*\orlig.fic" (
  echo.%_ipLocal%       apisolware.dms.dcs2.renault.com >> %_hosts%
  %EchoGreen% IP %_ipLocal% copier - OK
) else (
  set /p ipServ= "IP du serveur :" 
  echo.!ipServ!     apisolware.dms.dcs2.renault.com >> %_hosts%
  %EchoGreen% IP !ipServ! copier - OK
)
TIMEOUT /T 5
exit /b

::========================================================================================================================================

REM Redemarrage des services

:RestartServices
cls
setlocal enabledelayedexpansion
title Redemarrage des services...

echo Redemarrage des services...

REM Verification si les services existent bien
REM On redemarra tout les services

echo ============ Redemarrage des Services ============
(for %%i in (%ServicesLIST%) do ( 
   sc query %%i >nul 2>&1
   if errorlevel 1060 %EchoRed% Service %%i : manquant
   (for /F "tokens=3 delims=: " %%H in ('sc query %%i^|find /i "STATE"') do (
    if /I "%%H" EQU "RUNNING" (
       net stop %%i >nul 2>&1
       if %errorlevel% == 0 net start %%i >nul 2>&1
       if %errorlevel% == 0 echo Redemarrage de %%i : OK ^!
      )
      if /I "%%H" EQU "STOPPED" (
       net start "%%i" >nul
       if %errorlevel% == 2 %EchoRed% Impossible de demarrer le service %%i
       if %errorlevel% == 0 echo Lancement de %%i : OK ^!
      )
    ))
))
echo ================================================== & echo.
%EchoGreen% Redemarrage des services - Fini ^!

TIMEOUT /T 5                
goto:Extras

::========================================================================================================================================

REM Generation du fichier TXT

:ReadMe
setlocal enabledelayedexpansion

cls
set "_ReadMe=%SystemRoot%\Temp\infos.txt"
if exist "%_ReadMe%" del /f /q "%_ReadMe%" %_null%
call :_export %1 "%_ReadMe%" ASCII
start notepad "%_ReadMe%"
exit /b

::========================================================================================================================================

REM F.A.Q - Informations

:faq:
==========================================================================================================================================
Informations (06/06/2022)
==========================================================================================================================================

    1. Erreur Fleetbox - Work Order Support
       Verifier le navigateur par defaut dans Winmotor [Parametre > Options > Interfaces]
       Le contenu du champ doit etre C:\program files\internet explorer\iexplore.exe

    2. Un site ne s'ouvre pas avec Internet Explorer
       Verifier que le lien du site figure dans la liste, ouvrir Notepad puis Fichier > Ouvrir et y entrer %USERPROFILE%\Solware\list.xml
       Ouvrir Edge puis se rendre dans edge://compat puis cliquer sur Forcer la mise a jour. (sans quoi il vous serra obligatoire de patienter 65 secondes pour qu'elle se mette a jour)
       
    3. Servicebox Erreur - 2146828218 Permission refusee [*]
       Pour Citroen Services il est possible que l'erreur - 2146828218 Permission refusee se declare, il faut de faire le choix (Permission Servicebox) sur le menu principal.
       
    4. Internet Explorer a expressement revoque le certificat ou ce site n'est pas securise - [https://apisolware.dms.dcs2.renault.com][*]
       Ce probleme vient du certificat non installer ou rejeter par l'antivirus il peux egalement venir du fait que TLS 1.1/1.2 ne soit pas actif.
       Pour resoudre le probleme vous devez installer le certificat depuis le menu (Extras) puis selectionner le menu (Installer le certificat).
       Et activer le TLS 1.1/1.2 en choisissant (Activer TLS 1.2 / 1.1).
              
    5. Un des site n'est pas compatible, et l'icone d'Internet Explorer n'apparait pas a cote de l'URL dans Edge.
       Me contacter par mail ou teams pour que je puisse l'ajouter dans la liste des sites compatibles.

[*] Indique qu'il est possible que cette option soit desactiver par une reinitialisation du navigateur.
Pour plus d'informations, vous pouvez me contacter (Asmir Belkic) sur Teams.
:faq:

::========================================================================================================================================

:_Export
%_nul% %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split \":%~1\:.*`n\"; [IO.File]::WriteAllText('%~2',$f[1].Trim(),[System.Text.Encoding]::%~3)"
exit /b

::========================================================================================================================================

REM ajout des domaines "*.mpsa.com", "*.peugeot.com" et "*.citroen.com" dans les parametres d'affichage de compat. pour IE10 et IE11

:paramIE
reg add "HKCU\Software\Microsoft\Internet Explorer\BrowserEmulation\ClearableListData" /v "UserFilter" /t REG_BINARY /d "411f00005308adba030000007e00000001000000030000000c000000932092e4f01ccf010100000008006d007000730061002e0063006f006d000c0000003ba746a62148cf01010000000b00700065007500670065006f0074002e0063006f006d000c000000a7657da82148cf01010000000b0063006900740072006f0065006e002e0063006f006d00" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Internet Explorer\Privacy" /v "ClearBrowsingHistoryOnExit" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones" /v "SecuritySafe" /t REG_DWORD /d "1" /f 2>&1 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2001" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2004" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "DisplayName" /t REG_SZ /d "Sites de confiance" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "PMDisplayName" /t REG_SZ /d "Trusted sites [Protected Mode]" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "Description" /t REG_SZ /d "Cette zone contient les sites Web auxquels vous faites confiance." /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "Icon" /t REG_SZ /d "inetcpl.cpl#00004480" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "LowIcon" /t REG_SZ /d "inetcpl.cpl#005424" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "CurrentLevel" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "Flags" /t REG_DWORD /d "67" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1201" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1406" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1607" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1609" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap" /v "UNCAsIntranet" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap" /v "AutoDetect" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap" /v "ProxyBypass" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap" /v "IntranetName" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\citroen.com" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\citroen.com" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\inetpsa.com" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\mpsa.com" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\mpsa.com" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\peugeot.com" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\peugeot.com" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoft.com\*.update" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoft.com\*.update" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "http" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "https" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "ftp" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "file" /t REG_DWORD /d "3" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "@ivt" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "shell" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\ProtocolDefaults" /v "knownfolder" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range1" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range1" /v ":Range" /t REG_SZ /d "192.*.*.*" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range2" /v "http" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range2" /v ":Range" /t REG_SZ /d "10.*.*.*" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range3" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range3" /v ":Range" /t REG_SZ /d "apisolware.dms.dcs2.renault.com" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Internet Explorer\New Windows" /v "PopupMgr" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\athoris.net" /v "https" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" /v CertificateRevocation /t REG_DWORD /d 0 /f >nul 2>&1
cls
echo Le parametrage d'Internet Explorer s'est bien deroule.
TIMEOUT /t 5
goto :MainMenu

::========================================================================================================================================
REM Patch de TLS 1.1 et 1.2
:PatchTLS

REM Activation de TLS 1.2 CLIENT
reg add "HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "Enabled" /t REG_DWORD /d "ffffffff" /f >nul 2>&1
reg add "HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "DisabledByDefault" /t REG_DWORD /d "00000000" /f >nul 2>&1

REM Activation de TLS 1.2 SERVER
reg add "HKLM\SYSTEM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "Enabled" /t REG_DWORD /d "ffffffff" /f >nul 2>&1
reg add "HKLM\SYSTEM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "DisabledByDefault" /t REG_DWORD /d "00000000" /f >nul 2>&1

REM Activation de TLS 1.1 CLIENT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "DisabledByDefault" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "DisabledByDefault" /t REG_DWORD /d "0" /f >nul 2>&1
cls
echo Le parametrage de TLS s'est bien deroule.
TIMEOUT /T 5
goto:Extras 

::========================================================================================================================================

REM Installation du certificat local - https://apisolware.dms.dcs2.renault.com

:InstallCert
set "_psc=powershell"
set "nul=1>nul 2>nul"
set "_batf=%~f0"
set "_batp=%_batf:'=''%"


REM On installe 
set "temp_=%SystemRoot%\Temp\"
if exist "%temp_%\" @RD /S /Q "%temp_%\" %_null%
md "%temp_%\" %_null%
pushd "%temp_%\"

REM On extrait le certificat
%nul% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':bat2file\:.*';iex ($f[1]);X 1;X 2;"

set "rootCert=%temp_%\rootCA.crt"
certutil -addstore root %rootCert% >nul 2>&1
if errorlevel 0 echo L'installation du certificat s'est bien deroule. & del /f /q %rootCert%
TIMEOUT /T 5
goto :Extras

:bat2file: Compressed2TXT v6.5
$k='.,;{-}[+](/)_|^=?O123456789ABCDeFGHyIdJKLMoN0PQRSTYUWXVZabcfghijklmnpqrstuvwxz!@#$&~E<*`%\>'; Add-Type -Ty @'
using System.IO;public class BAT91{public static void Dec(ref string[] f,int x,string fo,string key){unchecked{int n=0,c=255,q=0
,v=91,z=f[x].Length; byte[]b91=new byte[256]; while(c>0) b91[c--]=91; while(c<91) b91[key[c]]=(byte)c++; using (FileStream o=new
FileStream(fo,FileMode.Create)){for(int i=0;i!=z;i++){c=b91[f[x][i]]; if(c==91)continue; if(v==91){v=c;}else{v+=c*91;q|=v<<n;if(
(v&8191)>88){n+=13;}else{n+=14;}v=91;do{o.WriteByte((byte)q);q>>=8;n-=8;}while(n>7);}}if(v!=91)o.WriteByte((byte)(q|v<<n));} }}}
'@; cd -Lit($env:__CD__); function X([int]$x=1){[BAT91]::Dec([ref]$f,$x+1,$x,$k); expand -R $x -F:* .; del $x -force}

:bat2file:[ rootCA_crt
::AVEYO...r!P,......*D........j}?.k...r!B,..){..d,qGy+??........Q5RV.om}Drg~<LY{XsL#Y;~+ixO(I,??.]H>Y,Drlkxv;PM.6)[^*Dn{Oh\@Al,!lDWu
::%x*IgzM@pP@?]+S_@5y=2na}=3..I.ns].91tIU8r=Bk.#FV[VbKq-IoXvkqrnwB-asy#*tnu)>QwF.*>ax\&\?/u;v;....W-!5~RWb)t%&a0T/&ZA<{Zy`?eV[#]ya0r
::ttl;*)\aC)y`Fj>qLQ&>_^d|jnmb[-ejP^s5yKu@<Ua;zS=[=H*xEs}WNGwD.X~O<d-Pz&zxELUy]Y&d[PD{!71bOtb=t1GrDBS~79*%}\~AY^6C8/|},;=)OUu<tG0?jp
::A^x~#O<[.`CfLY5\}fES&(6;9Em*wkG*T24*eM//ddU#U1Z3yo;a_&lCX_|-qT>LoDx^cb$c+gK63EZBIxyi!A7@$%U&{$mPA;9_Ok/jw%6,[(rjRRUu]~@FZ/uYc8zt)3
::<tG%mE`$a$f0J!AYk!#h0Cvzu\OmsY.fRfTKz<m!Ah@<YA-mLrg7cQt[BL*954Uv>U!(v2t8a1)&=O;8(!ELIgQk4TqI.AaDr(hU1xqe+}]fnkCZe*&Uqm\XZov#Rox7)t
::1,VPSChs;z6=p,>Goo|CRJ}e}6L;9T,L(lCqam1BMfa=!+l=m$lh^RMIXY$jznG<(3q%vM@Lr[4=1ETk{y;H(|UC-5r[8m}H#H!7Zk]Zg8dGKN9j{C_1V+1G#]OAEe1NOU
::{2A/\0pmd^R>}kTjPyz).!r&mWNtPlXx(BZ3xPVJs9Iz]6e_=I@ta^MTh/5L*hwnevjOLE)I+nHfpy%4;eC?-4MA=$wSbdve^L_tR/Q(8zDW9NiOgDc{-1tL1S*jp3v;Rd
::X-em&lI,mH!sKKX=f^2I7=lP~[(z&w.jzNO_OYSUs}YB1m6Fp0a<)DP*&/L;,yn`aSs<Mqb>1!}xDrfx]<LPSk_arfCU$n[`yV\CI>/rG#*Emx,d#nk{b/b`BWXEbs-Xx@
::EQ2JpY+BQGnh+oY~Z`?}Wj<o.WJJ,vs}MC!2M&igd{PA6k[I|RPN7B!p0z0*gi{Fn~jUeu9v^a\10#{^Bz~VN38_AFx!roY7YT/5c`9i);^$+d6,sD20ST02T|}TWC*SN=
::HS?n[hLq!?tRr_]S*CBRiTBSst_W@wb%7*Pt]Y{j29&@%#PG`(6e&ixO_XU%.e5HMj|l6xWf<QcKdAB4z3[3&[<ig3E`lu*Sg?Pq[&zg)9x+/GwBbVI!O2Eb~85f9+J(Z5
::V,sRs4^0k@|=[[<Gt?*4R&E=>d7`Yd4$~m}^qk(u*9l;
:bat2file:]

::========================================================================================================================================

REM Fermeture avec message

:SOLClose
echo:
echo Appuyez sur une touche pour quitter...
pause >nul
exit /b