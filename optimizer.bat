@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 (HDD/SSD) - BM JAYA 2 v2.4

:: OPTIMIZER_SIGNATURE: BMJAYA2
:: ======================================================================
:: System Optimizer Windows 10 - POS & PC Reguler
:: Pengembang : Khairullah Irfansyah, S.Kom
:: Unit       : BM JAYA 2
:: Kompatibel : Windows 10 1507 (Build 10240) s.d. 22H2 (Build 19045)
:: Tidak membuat atau menghapus berkas .log.
:: ======================================================================

set "SELF_PATH=%~f0"
set "SELF_DIR=%~dp0"
set "CURRENT_VER=2.4"
set "APP_NAME=System Optimizer Windows 10 (POS & Office)"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"
set "GUID_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "GUID_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"

:: Memerlukan administrator; path batch disampaikan lewat environment agar
:: aman bila nama folder memuat spasi.
%SystemRoot%\System32\fltmc.exe >nul 2>&1
if errorlevel 1 (
    where powershell.exe >nul 2>&1
    if errorlevel 1 (
        cls
        echo.
        echo [!] HAK ADMINISTRATOR DIBUTUHKAN
        echo Klik kanan file ini, lalu pilih "Run as administrator".
        echo.
        pause
        exit /b 1
    )
    echo [*] Meminta hak Administrator melalui UAC...
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:SELF_PATH -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo [!] UAC dibatalkan atau gagal.
        pause
        exit /b 1
    )
    exit /b 0
)

setlocal EnableDelayedExpansion
pushd "!SELF_DIR!" >nul 2>&1
mode con: cols=88 lines=42 >nul 2>&1
color 0B

:: Bersihkan hanya updater lama milik script ini; tidak menyentuh file aplikasi.
del /f /q "%TEMP%\BMJAYA2_update_*.bat" >nul 2>&1

:: ======================================================================
:: DETEKSI WINDOWS DAN TOOL
:: ======================================================================
set "WIN_BUILD=Unknown"
set "WIN_VER=Win10"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i /c:"CurrentBuildNumber"') do set "WIN_BUILD=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul ^| findstr /i /c:"DisplayVersion"') do set "WIN_VER=%%A"
if "!WIN_VER!"=="Win10" for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^>nul ^| findstr /i /c:"ReleaseId"') do set "WIN_VER=%%A"
if "!WIN_BUILD!"=="10240" if "!WIN_VER!"=="Win10" set "WIN_VER=1507"

set "HAS_PS=0"
where powershell.exe >nul 2>&1 && set "HAS_PS=1"
call :DetectDisk

:: ======================================================================
:: PEMBARUAN GITHUB
:: Pembaruan memakai HTTPS tervalidasi dan memeriksa isi file lebih dulu.
:: ======================================================================
:CHECK_UPDATE
if "!HAS_PS!"=="0" goto MENU
cls
echo.
echo ======================================================================
echo !APP_NAME! - BM JAYA 2 v!CURRENT_VER!
echo ======================================================================
echo [*] Memeriksa pembaruan dari GitHub...

set "REMOTE_VER="
set "NOCACHE=?t=!RANDOM!!RANDOM!!RANDOM!"
call :GetRemoteVersion "!VER_URL!!NOCACHE!"
if not defined REMOTE_VER goto MENU
call :SanitizeVersion "!REMOTE_VER!"
if not defined REMOTE_VER goto MENU
call :CheckVersion "!REMOTE_VER!" "!CURRENT_VER!"
if /i not "!IS_NEW!"=="YES" goto MENU

echo [*] Versi baru terdeteksi: v!REMOTE_VER!
echo [*] Mengunduh pembaruan...
set "UPDATER_TMP=%TEMP%\BMJAYA2_update_!RANDOM!!RANDOM!.bat"
call :GetRemoteFile "!UPDATE_URL!!NOCACHE!" "!UPDATER_TMP!"
if not exist "!UPDATER_TMP!" goto SKIP_UPDATE
call :ValidateUpdate "!UPDATER_TMP!" "!REMOTE_VER!"
if not "!UPDATE_VALID!"=="1" goto SKIP_UPDATE

echo [OK] Memasang versi baru v!REMOTE_VER!...
:: Proses terpisah menunggu file batch ini selesai lalu melakukan copy dengan retry.
:: Tidak ada runner atau file log tambahan yang dibuat.
set "UPDATER_SOURCE=!UPDATER_TMP!"
start "" /min powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$src=$env:UPDATER_SOURCE; $dst=$env:SELF_PATH; for($i=0;$i -lt 12;$i++){ Start-Sleep -Milliseconds 500; try { [IO.File]::Copy($src,$dst,$true); if((Get-Item -LiteralPath $dst).Length -gt 0){ Remove-Item -LiteralPath $src -Force -ErrorAction SilentlyContinue; Start-Process -FilePath $dst; exit 0 } } catch {} }; Remove-Item -LiteralPath $src -Force -ErrorAction SilentlyContinue; exit 1" >nul 2>&1
popd >nul 2>&1
exit /b 0

:SKIP_UPDATE
if defined UPDATER_TMP if exist "!UPDATER_TMP!" del /f /q "!UPDATER_TMP!" >nul 2>&1
set "UPDATER_TMP="

:: ======================================================================
:: MENU UTAMA
:: ======================================================================
:MENU
cls
echo.
echo ======================================================================
echo  !APP_NAME! [v!CURRENT_VER!]
echo  Pengembang : Khairullah Irfansyah, S.Kom
echo  Unit       : BM JAYA 2
echo  Target     : Komputer Kasir ^(POS^) ^& PC Reguler ^(Windows 10^)
echo  Sistem     : Windows 10 !WIN_VER! ^(Build !WIN_BUILD!^) ^| Disk: !DISK_TYPE!
echo ======================================================================
echo.
echo  [1] Jalankan Optimasi Aman ^(sesuai disk dan aman untuk POS^)
echo  [2] Kembalikan Pengaturan yang Diubah ke Standar Windows
echo  [3] Cek Status Sistem Singkat ^(diagnostik^)
echo  [4] Keluar
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto MENU_FALLBACK
choice /C 1234 /N /M " Pilih menu [1-4]"
set "MENU_ERR=!errorlevel!"
if "!MENU_ERR!"=="4" goto QUIT
if "!MENU_ERR!"=="3" goto DIAGNOSTICS
if "!MENU_ERR!"=="2" goto RESTORE_DEFAULTS
if "!MENU_ERR!"=="1" goto OPTIMIZE
goto MENU

:MENU_FALLBACK
set "MENU_CHOICE="
set /p "MENU_CHOICE= Pilih menu [1-4]: "
if defined MENU_CHOICE set "MENU_CHOICE=!MENU_CHOICE: =!"
if "!MENU_CHOICE!"=="4" goto QUIT
if "!MENU_CHOICE!"=="3" goto DIAGNOSTICS
if "!MENU_CHOICE!"=="2" goto RESTORE_DEFAULTS
if "!MENU_CHOICE!"=="1" goto OPTIMIZE
goto MENU

:: ======================================================================
:: OPTIMASI
:: ======================================================================
:OPTIMIZE
cls
echo.
echo ======================================================================
echo  MEMULAI OPTIMASI AMAN ^(MODE DISK: !DISK_TYPE!^)
echo ======================================================================
echo.

echo [1/7] Mengatur layanan latar dan menjaga printer/network sharing...
if /i "!DISK_TYPE!"=="HDD" (
    echo  - Disk sistem HDD: SysMain dinonaktifkan untuk mengurangi I/O acak.
    call :ManagePrefetch disabled
) else (
    echo  - Disk SSD/tidak terdeteksi: SysMain dipertahankan aktif agar aman.
    call :ManagePrefetch auto
)
call :ManageService WSearch auto
call :ManageService DiagTrack disabled
call :ManageService dmwappushservice demand
call :ManageService MapsBroker demand
call :ManageService WerSvc demand
call :ManageService DoSvc demand
call :ManageService BITS demand
call :ManageService Spooler auto
call :ManageService LanmanServer auto
call :ManageService LanmanWorkstation auto
echo.

echo [2/7] Mengoptimalkan perilaku NTFS...
set "_FSUTIL_VAL=1"
if not "!WIN_BUILD!"=="Unknown" (
    if !WIN_BUILD! GEQ 17134 set "_FSUTIL_VAL=3"
)
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess !_FSUTIL_VAL! >nul 2>&1
if /i "!DISK_TYPE!"=="SSD" (
    %SystemRoot%\System32\fsutil.exe behavior set DisableDeleteNotify 0 >nul 2>&1
    echo  - LastAccess dikurangi dan TRIM SSD dipastikan aktif.
) else (
    echo  - Pencatatan LastAccess dikurangi untuk meringankan aktivitas disk.
)
echo.

echo [3/7] Mengatur respons antarmuka tanpa memaksa aplikasi POS ditutup...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1
echo  - Menu dan animasi jendela dipercepat; timeout aplikasi tidak diubah.
echo.

echo [4/7] Mengurangi efek visual berat untuk pengguna saat ini...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
echo  - Transparansi dan animasi berat dimatikan tanpa kebijakan semua pengguna.
echo.

echo [5/7] Menyegarkan cache DNS...
ipconfig /flushdns >nul 2>&1
echo  - Cache DNS disegarkan; IP statis, printer sharing, dan database POS aman.
echo.

echo [6/7] Mengatur daya agar disk dan USB printer tidak sleep saat terhubung listrik...
call :SetOptimizedPower
echo  - High Performance aktif; disk, sleep, dan USB selective suspend pada AC disetel aman.
echo.

echo [7/7] Membersihkan berkas sampah (Temp, Cache AppData aman, ^& Recycle Bin)...
call :CleanJunk
echo  - Temp pengguna, Temp sistem, cache dump AppData, dan Recycle Bin telah dibersihkan.
echo.

echo ======================================================================
echo  [OK] OPTIMASI SELESAI ^(v!CURRENT_VER! - Mode !DISK_TYPE!^)
echo ======================================================================
echo  - Tidak membuat atau menghapus berkas .log penting.
echo  - Berkas sampah (%TEMP%, Windows Temp, Cache AppData, Recycle Bin) dibersihkan.
echo  - Sharing printer ^(Spooler/SMB^), IP statis LAN, dan data POS tidak diubah.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto OPTIMIZE_FALLBACK
choice /C YN /N /M " Restart Explorer agar efek visual langsung terasa [Y/N]"
if "!errorlevel!"=="1" goto RESTART_EXPLORER
goto MENU

:OPTIMIZE_FALLBACK
set "EXP_CHOICE="
set /p "EXP_CHOICE= Restart Explorer sekarang? [Y/N]: "
if /i "!EXP_CHOICE!"=="Y" goto RESTART_EXPLORER
goto MENU

:RESTART_EXPLORER
echo.
echo [*] Me-restart Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start "" "%SystemRoot%\explorer.exe"
echo [OK] Explorer berhasil dijalankan ulang.
timeout /t 2 /nobreak >nul
goto MENU

:: ======================================================================
:: KEMBALIKAN PENGATURAN
:: ======================================================================
:RESTORE_DEFAULTS
cls
echo.
echo ======================================================================
echo  KEMBALIKAN PENGATURAN YANG DIUBAH KE STANDAR WINDOWS
echo ======================================================================
echo.
echo  Layanan SysMain, Windows Search, tampilan, NTFS, dan power plan
echo  akan dikembalikan ke pengaturan Windows yang umum.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_FALLBACK
choice /C YN /N /M " Lanjutkan reset pengaturan [Y/N]"
if "!errorlevel!"=="2" goto MENU
goto RESTORE_GO

:RESTORE_FALLBACK
set "RST_CHOICE="
set /p "RST_CHOICE= Lanjutkan reset pengaturan? [Y/N]: "
if /i not "!RST_CHOICE!"=="Y" goto MENU

:RESTORE_GO
echo.
echo [*] Mengembalikan layanan Windows...
call :ManagePrefetch auto
call :ManageService WSearch auto
call :ManageService DiagTrack auto
call :ManageService dmwappushservice demand
call :ManageService MapsBroker demand
call :ManageService WerSvc demand
call :ManageService DoSvc demand
call :ManageService BITS demand
call :ManageService Spooler auto
call :ManageService LanmanServer auto
call :ManageService LanmanWorkstation auto

echo [*] Mengembalikan perilaku NTFS dan tampilan...
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 2 >nul 2>&1 || %SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 0 >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1

echo [*] Mengembalikan power plan umum Windows...
call :SetDefaultPower
echo.
echo [OK] Pengaturan script telah dikembalikan ke standar Windows yang umum.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_EXP_FALLBACK
choice /C YN /N /M " Restart Explorer sekarang [Y/N]"
if "!errorlevel!"=="1" goto RESTART_EXPLORER
goto MENU

:RESTORE_EXP_FALLBACK
set "REX_CHOICE="
set /p "REX_CHOICE= Restart Explorer sekarang? [Y/N]: "
if /i "!REX_CHOICE!"=="Y" goto RESTART_EXPLORER
goto MENU

:: ======================================================================
:: DIAGNOSTIK
:: ======================================================================
:DIAGNOSTICS
cls
echo.
echo ======================================================================
echo  DIAGNOSTIK RINGKAS SISTEM
echo ======================================================================
echo.
echo [Identitas PC]
echo  - Nama PC     : %COMPUTERNAME%
echo  - Pengguna    : %USERNAME%
echo  - Versi OS    : Windows 10 !WIN_VER! ^(Build !WIN_BUILD!^)
echo.
echo [Storage / Disk Utama ^(%SystemDrive%^)]
call :DetectDisk
echo  - Tipe Disk   : !DISK_TYPE!
set "FREE_GB="
if "!HAS_PS!"=="1" for /f "delims=" %%A in (`powershell.exe -NoProfile -NonInteractive -Command "try { $d=New-Object System.IO.DriveInfo($env:SystemDrive); [math]::Round($d.AvailableFreeSpace / 1GB, 2) } catch {}" 2^>nul`) do if not defined FREE_GB set "FREE_GB=%%A"
if defined FREE_GB (
    echo  - Sisa Ruang  : !FREE_GB! GB
) else (
    echo  - Sisa Ruang  : Tidak dapat dibaca
)
echo.
echo [Status Efek Transparansi]
set "TRANSP_STATUS=Tidak Diketahui"
for /f "tokens=3" %%A in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency 2^>nul ^| findstr /i /c:"EnableTransparency"') do set "TRANSP_STATUS=%%A"
if /i "!TRANSP_STATUS!"=="0x0" set "TRANSP_STATUS=MATI [Dioptimasi]"
if /i "!TRANSP_STATUS!"=="0x1" set "TRANSP_STATUS=AKTIF [Default]"
echo  - Transparansi: !TRANSP_STATUS!
echo.
echo [Status Layanan Kunci ^& Printer]
call :ShowPrefetchSvc
call :ShowSvc WSearch
call :ShowSvc DiagTrack
call :ShowSvc Spooler
call :ShowSvc LanmanServer
echo.
echo [Power Plan Aktif]
for /f "delims=" %%A in ('powercfg /getactivescheme 2^>nul') do echo  - %%A
echo.
pause
goto MENU

:: ======================================================================
:: SUBROUTINE: UPDATE GITHUB
:: ======================================================================
:GetRemoteVersion
set "REMOTE_VER="
set "FETCH_URL=%~1"
for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $wc=New-Object Net.WebClient; $wc.Headers['Cache-Control']='no-cache'; ($wc.DownloadString($env:FETCH_URL)).Trim() } catch {}" 2^>nul`) do if not defined REMOTE_VER set "REMOTE_VER=%%A"
exit /b 0

:CheckVersion
set "IS_NEW="
set "NEW_VERSION=%~1"
set "OLD_VERSION=%~2"
for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -NonInteractive -Command "try { if([version]$env:NEW_VERSION -gt [version]$env:OLD_VERSION){ 'YES' } } catch {}" 2^>nul`) do if /i "%%A"=="YES" set "IS_NEW=YES"
exit /b 0

:SanitizeVersion
set "SV_RAW=%~1"
set "REMOTE_VER="
for /l %%I in (0,1,31) do (
    set "SV_CHAR=!SV_RAW:~%%I,1!"
    if defined SV_CHAR for %%C in (0 1 2 3 4 5 6 7 8 9 .) do if "!SV_CHAR!"=="%%C" set "REMOTE_VER=!REMOTE_VER!%%C"
)
exit /b 0

:GetRemoteFile
set "FETCH_URL=%~1"
set "FETCH_FILE=%~2"
if exist "!FETCH_FILE!" del /f /q "!FETCH_FILE!" >nul 2>&1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $wc=New-Object Net.WebClient; $wc.Headers['Cache-Control']='no-cache'; $wc.DownloadFile($env:FETCH_URL,$env:FETCH_FILE) } catch { exit 1 }" >nul 2>&1
exit /b 0

:ValidateUpdate
set "UPDATE_VALID=0"
set "CHECK_FILE=%~1"
set "CHECK_VER=%~2"
if not exist "!CHECK_FILE!" exit /b 0
for %%Z in ("!CHECK_FILE!") do if %%~zZ LSS 1024 exit /b 0
findstr /b /c:"@echo off" "!CHECK_FILE!" >nul 2>&1 || exit /b 0
findstr /i /c:"OPTIMIZER_SIGNATURE: BMJAYA2" "!CHECK_FILE!" >nul 2>&1 || exit /b 0
findstr /i /c:"CURRENT_VER=!CHECK_VER!" "!CHECK_FILE!" >nul 2>&1 || exit /b 0
set "UPDATE_VALID=1"
exit /b 0

:: ======================================================================
:: SUBROUTINE: SISTEM
:: ======================================================================
:DetectDisk
set "DISK_TYPE=UNKNOWN"
if "!HAS_PS!"=="0" exit /b 0
for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -NonInteractive -Command "try { $letter=$env:SystemDrive.Substring(0,1); $p=Get-Partition -DriveLetter $letter -ErrorAction Stop; $d=Get-Disk -Number $p.DiskNumber -ErrorAction Stop; if($d.BusType -eq 'NVMe' -or $d.MediaType -eq 'SSD' -or $d.FriendlyName -match 'SSD|NVMe|Solid'){ 'SSD' } elseif($d.MediaType -eq 'HDD'){ 'HDD' } else { 'UNKNOWN' } } catch { 'UNKNOWN' }" 2^>nul`) do (
    if /i "%%A"=="SSD" set "DISK_TYPE=SSD"
    if /i "%%A"=="HDD" set "DISK_TYPE=HDD"
)
exit /b 0

:ManagePrefetch
%SystemRoot%\System32\sc.exe query "SysMain" >nul 2>&1
if not errorlevel 1 (
    call :ManageService SysMain %~1
    exit /b 0
)
%SystemRoot%\System32\sc.exe query "Superfetch" >nul 2>&1
if not errorlevel 1 (
    call :ManageService Superfetch %~1
    exit /b 0
)
echo  - SysMain/Superfetch : Tidak ditemukan di sistem ini
exit /b 0

:ShowPrefetchSvc
%SystemRoot%\System32\sc.exe query "SysMain" >nul 2>&1
if not errorlevel 1 (
    call :ShowSvc SysMain
    exit /b 0
)
call :ShowSvc Superfetch
exit /b 0

:ManageService
set "SVC=%~1"
set "ACTION=%~2"
%SystemRoot%\System32\sc.exe query "!SVC!" >nul 2>&1
if errorlevel 1 exit /b 0
if /i "!ACTION!"=="disabled" (
    %SystemRoot%\System32\sc.exe config "!SVC!" start= disabled >nul 2>&1
    %SystemRoot%\System32\sc.exe stop "!SVC!" >nul 2>&1
    echo  - !SVC! : Dimatikan [Disabled]
    exit /b 0
)
if /i "!ACTION!"=="demand" (
    %SystemRoot%\System32\sc.exe config "!SVC!" start= demand >nul 2>&1
    echo  - !SVC! : Disetel Manual [On-Demand]
    exit /b 0
)
if /i "!ACTION!"=="auto" (
    %SystemRoot%\System32\sc.exe config "!SVC!" start= auto >nul 2>&1
    %SystemRoot%\System32\sc.exe start "!SVC!" >nul 2>&1
    echo  - !SVC! : Diaktifkan [Auto]
    exit /b 0
)
exit /b 0

:SetOptimizedPower
powercfg /setactive %GUID_HIGH% >nul 2>&1 || (
    powercfg -duplicatescheme %GUID_HIGH% >nul 2>&1
    powercfg /setactive %GUID_HIGH% >nul 2>&1
)
powercfg /change disk-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
exit /b 0

:SetDefaultPower
powercfg /setactive %GUID_BALANCED% >nul 2>&1 || powercfg /setactive SCHEME_BALANCED >nul 2>&1
powercfg /change disk-timeout-ac 20 >nul 2>&1
powercfg /change standby-timeout-ac 30 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
exit /b 0

:CleanJunk
:: 1. Bersihkan %TEMP% (AppData\Local\Temp milik user saat ini)
if defined TEMP if exist "%TEMP%\" (
    del /f /s /q "%TEMP%\*" >nul 2>&1
    for /d %%D in ("%TEMP%\*") do rd /s /q "%%~fD" >nul 2>&1
)
:: 2. Bersihkan Windows Temp (%SystemRoot%\Temp)
if exist "%SystemRoot%\Temp\" (
    del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
    for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%~fD" >nul 2>&1
)
:: 3. Bersihkan sampah aman di dalam %APPDATA% & %LOCALAPPDATA% (Tanpa merusak data POS/Browser)
if defined APPDATA (
    if exist "%APPDATA%\Microsoft\Windows\Recent\" del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
)
if defined LOCALAPPDATA (
    if exist "%LOCALAPPDATA%\CrashDumps\" del /f /s /q "%LOCALAPPDATA%\CrashDumps\*" >nul 2>&1
    if exist "%LOCALAPPDATA%\Temp\" (
        del /f /s /q "%LOCALAPPDATA%\Temp\*" >nul 2>&1
        for /d %%D in ("%LOCALAPPDATA%\Temp\*") do rd /s /q "%%~fD" >nul 2>&1
    )
    if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache\IE\" (
        del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache\IE\*" >nul 2>&1
        for /d %%D in ("%LOCALAPPDATA%\Microsoft\Windows\INetCache\IE\*") do rd /s /q "%%~fD" >nul 2>&1
    )
    if exist "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive\" (
        for /d %%D in ("%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive\*") do rd /s /q "%%~fD" >nul 2>&1
    )
    if exist "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue\" (
        for /d %%D in ("%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue\*") do rd /s /q "%%~fD" >nul 2>&1
    )
)
:: 4. Bersihkan laporan error sistem (Windows Error Reporting ProgramData)
if exist "%ProgramData%\Microsoft\Windows\WER\ReportArchive\" (
    for /d %%D in ("%ProgramData%\Microsoft\Windows\WER\ReportArchive\*") do rd /s /q "%%~fD" >nul 2>&1
)
if exist "%ProgramData%\Microsoft\Windows\WER\ReportQueue\" (
    for /d %%D in ("%ProgramData%\Microsoft\Windows\WER\ReportQueue\*") do rd /s /q "%%~fD" >nul 2>&1
)
:: 5. Kosongkan Recycle Bin di seluruh drive yang terpasang (Kompatibel Win 10 1507 - 22H2)
for %%L in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%L:\$Recycle.Bin\" rd /s /q "%%L:\$Recycle.Bin" >nul 2>&1
)
exit /b 0

:ShowSvc
set "ST=Tidak Terpasang"
for /f "tokens=3 delims=: " %%A in ('%SystemRoot%\System32\sc.exe query "%~1" 2^>nul ^| findstr /i /c:"STATE"') do set "ST=%%A"
echo  - %~1 : !ST!
exit /b 0

:QUIT
popd >nul 2>&1
endlocal
exit /b 0
