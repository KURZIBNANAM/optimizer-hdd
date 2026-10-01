@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v2.0

:: ======================================================================
:: IDENTITAS & KONFIGURASI
:: v2.0 memperbaiki crash menu [1]: kutip PowerShell di for /f
:: memotong parser CMD, sehingga jendela tertutup sendiri.
:: ======================================================================
set "CURRENT_VER=2.0"
set "APP_NAME=System Optimizer Windows 10 HDD"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"
set "GUID_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "GUID_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"

:: ======================================================================
:: CEK ADMINISTRATOR + AUTO UAC
:: ======================================================================
fltmc >nul 2>&1
if errorlevel 1 (
    where powershell >nul 2>&1
    if errorlevel 1 (
        cls
        echo.
        echo  ==========================================================================
        echo   [!] HAK ADMINISTRATOR DIBUTUHKAN
        echo  ==========================================================================
        echo   Script ini memerlukan hak administrator.
        echo   Klik kanan file ini, lalu pilih: "Run as administrator"
        echo.
        pause
        exit /b 1
    )
    echo.
    echo   [*] Meminta hak Administrator via UAC...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -LiteralPath '%~f0' -Verb RunAs | Out-Null } catch { exit 1 }"
    if errorlevel 1 (
        echo.
        echo   [!] UAC dibatalkan atau gagal. Jendela tidak ditutup.
        echo   Jalankan ulang: klik kanan file ini, pilih Run as administrator.
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

pushd "%~dp0" >nul 2>&1
mode con: cols=88 lines=38 >nul 2>&1
color 0B

:: ======================================================================
:: DETEKSI VERSI WINDOWS
:: ======================================================================
set "WIN_BUILD=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WIN_BUILD=%%A"
if "%WIN_BUILD%"=="0" set "WIN_BUILD=Unknown"

:: ======================================================================
:: DETEKSI KETERSEDIAAN CURL / POWERSHELL
:: ======================================================================
set "HAS_CURL=0"
set "HAS_PS=0"
where curl.exe >nul 2>&1 && set "HAS_CURL=1"
where powershell.exe >nul 2>&1 && set "HAS_PS=1"

:: ======================================================================
:: AUTO UPDATE (NON-BLOCKING JIKA OFFLINE)
:: ======================================================================
:CHECK_UPDATE
if "!HAS_PS!"=="0" goto MENU
cls
echo.
echo  ==========================================================================
echo   %APP_NAME% - BM JAYA 2 v%CURRENT_VER%
echo  ==========================================================================
echo.
echo   [] Memeriksa pembaruan repository...
set "REMOTE_VER="

if not "!HAS_CURL!"=="1" goto FETCH_PS
for /f "usebackq tokens=1 delims= " %%A in (`curl.exe -L -s --fail --connect-timeout 2 -m 4 "!VER_URL!" 2^>nul`) do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)
goto FETCH_DONE

:FETCH_PS
for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadString($env:VER_URL).Trim() } catch {}" 2^>nul') do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

:FETCH_DONE

if not defined REMOTE_VER (
    echo   [i] Offline / repository tidak dapat dijangkau. Melewati update...
    timeout /t 1 /nobreak >nul
    goto MENU
)

set "REMOTE_VER=!REMOTE_VER:v=!"
set "REMOTE_VER=!REMOTE_VER:V=!"
set "REMOTE_VER=!REMOTE_VER: =!"
set "IS_NEW="
call :VerToNum CUR_NUM "!CURRENT_VER!"
call :VerToNum REM_NUM "!REMOTE_VER!"
if defined REM_NUM if defined CUR_NUM (
    if !REM_NUM! GTR !CUR_NUM! set "IS_NEW=YES"
)

if /i not "!IS_NEW!"=="YES" goto MENU
echo   [] Versi baru terdeteksi: v!REMOTE_VER!
echo   [*] Mengunduh script pembaruan...
set "UPDATER_TMP=%TEMP%\update_%RANDOM%.bat"

if "!HAS_CURL!"=="1" (
    curl.exe -L -s --fail --connect-timeout 4 -m 20 -o "!UPDATER_TMP!" "!UPDATE_URL!" >nul 2>&1
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile($env:UPDATE_URL, $env:UPDATER_TMP) } catch {}" >nul 2>&1
)

if not exist "!UPDATER_TMP!" goto SKIP_UPDATE
findstr /i /c:":MENU" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
findstr /i /c:"Khairullah Irfansyah" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
findstr /i /c:"CURRENT_VER" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
echo   [OK] Validasi berhasil. Memasang versi baru...
set "SELF_RUNNER=%TEMP%\replacer_%RANDOM%.bat"
(
echo @echo off
echo timeout /t 1 /nobreak ^>nul
echo copy /y "!UPDATER_TMP!" "%~f0" ^>nul
echo del /f /q "!UPDATER_TMP!" ^>nul
echo start "" "%~f0"
echo del /f /q "!SELF_RUNNER!" ^>nul
) > "!SELF_RUNNER!"
start "" /min "!SELF_RUNNER!"
exit /b 0

:SKIP_UPDATE
if defined UPDATER_TMP (
    echo   [!] Validasi gagal. File update tidak sah, ditolak.
    del /f /q "!UPDATER_TMP!" >nul 2>&1
    set "UPDATER_TMP="
)
timeout /t 2 /nobreak >nul

:: ======================================================================
:: MENU UTAMA
:: ======================================================================
:MENU
cls
echo.
echo  ==========================================================================
echo   %APP_NAME% - BM JAYA 2 [v%CURRENT_VER%]
echo   Pengembang : Khairullah Irfansyah, S.Kom
echo   Unit       : BM JAYA 2
echo   Target     : Komputer Kasir / POS ^& PC Kantor Berbasis HDD
echo   Windows    : Build %WIN_BUILD%
echo  ==========================================================================
echo.
echo   [1] Jalankan Optimasi HDD (POS Safe Mode)
echo   [2] Kembalikan ke Standar Default Windows
echo   [3] Cek Status Sistem Singkat (Diagnostik)
echo   [4] Keluar
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto MENU_FALLBACK
choice /C 1234 /N /M "  Pilih menu [1-4]: "
set "MENU_ERR=!errorlevel!"
if "!MENU_ERR!"=="4" goto QUIT
if "!MENU_ERR!"=="3" goto DIAGNOSTICS
if "!MENU_ERR!"=="2" goto RESTORE_DEFAULTS
if "!MENU_ERR!"=="1" goto OPTIMIZE
goto MENU

:MENU_FALLBACK
set /p "MENU_CHOICE=  Pilih menu [1-4]: "
set "MENU_CHOICE=!MENU_CHOICE: =!"
if "!MENU_CHOICE!"=="4" goto QUIT
if "!MENU_CHOICE!"=="3" goto DIAGNOSTICS
if "!MENU_CHOICE!"=="2" goto RESTORE_DEFAULTS
if "!MENU_CHOICE!"=="1" goto OPTIMIZE
goto MENU

:: ======================================================================
:: 1. PROSES OPTIMASI
:: ======================================================================
:OPTIMIZE
cls
echo.
echo  ==========================================================================
echo   MEMULAI OPTIMASI HDD (POS SAFE MODE)
echo  ==========================================================================
echo.
echo   [1/9] Memeriksa Disk ^& Mengatur Windows Service...
call :DetectDisk
if not defined DISK_TYPE set "DISK_TYPE=HDD"
echo         - Drive %SystemDrive% terdeteksi sebagai: !DISK_TYPE!
if /i "!DISK_TYPE!"=="SSD" (
    echo         - Drive sistem adalah SSD. Menjaga SysMain Auto.
    call :ManageService SysMain auto
) else (
    call :ManageService SysMain disabled
)
call :ManageService WSearch disabled
call :ManageService DiagTrack disabled
call :ManageService DoSvc demand
call :ManageService dmwappushservice demand
call :ManageService BITS demand
echo.
echo   [2/9] Mengelola Storage ^& Hibernasi...
powercfg /h off >nul 2>&1
echo         - Hibernasi dinonaktifkan (hiberfil.sys off).
echo.
echo   [3/9] Optimasi Responsivitas UI ^& Registry...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1 || echo         - Key BackgroundAccessApplications tidak tersedia, dilewati.
echo         - Delay menu, animasi, dan background apps diminimalkan.
echo.
echo   [4/9] Menonaktifkan Efek Transparansi Windows 10...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1 || echo         - Key Personalize tidak tersedia, dilewati.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /t REG_DWORD /d 1 /f >nul 2>&1 || echo         - Policy DWM tidak dapat dibuat, dilewati.
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1 || echo         - Key DWM tidak tersedia, dilewati.
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul 2>&1 || echo         - Key DWM tidak tersedia, dilewati.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1 || echo         - Key VisualEffects tidak tersedia, dilewati.
echo         - Transparansi dan visual effects disetel ke mode performa.
echo.
echo   [5/9] Mengurangi Beban Write Disk (NTFS)...
if /i not "!DISK_TYPE!"=="SSD" (
    %SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 1 >nul 2>&1 || echo         - fsutil tidak tersedia atau gagal, dilewati.
    echo         - Pencatatan waktu akses baca file dinonaktifkan.
) else (
    echo         - SSD terdeteksi, melewati tweak NTFS...
)
echo.
echo   [6/9] Membersihkan Cache Windows Update Lama...
set "WU_RUNNING="
sc query wuauserv 2>nul | findstr /i "RUNNING" >nul && set "WU_RUNNING=1"
if defined WU_RUNNING (
    echo         - Menghentikan Windows Update sementara...
    sc stop wuauserv >nul 2>&1
    sc stop bits >nul 2>&1
    timeout /t 2 /nobreak >nul
)
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
) else (
    echo         - Folder SoftwareDistribution tidak ditemukan, dilewati.
)
if defined WU_RUNNING (
    sc start wuauserv >nul 2>&1
    sc start bits >nul 2>&1
)
echo         - Cache update dibersihkan jika ada.
echo.
echo   [7/9] Pembersihan Cache ^& File Temp Aman...
ipconfig /flushdns >nul 2>&1
call :CleanSafeTemp "%TEMP%"
call :CleanSafeTemp "%SystemRoot%\Temp"
echo         - Cache DNS dan file temporary kadaluarsa dibersihkan.
echo.
echo   [8/9] Membersihkan Log Event Viewer...
%SystemRoot%\System32\wevtutil.exe cl Application >nul 2>&1 || echo         - wevtutil tidak tersedia, dilewati.
%SystemRoot%\System32\wevtutil.exe cl System >nul 2>&1 || echo         - wevtutil tidak tersedia, dilewati.
%SystemRoot%\System32\wevtutil.exe cl Setup >nul 2>&1 || echo         - wevtutil tidak tersedia, dilewati.
echo         - Log Application, System, dan Setup dikosongkan jika memungkinkan.
echo.
echo   [9/9] Mengaktifkan Mode High Performance...
powercfg /setactive %GUID_HIGH% >nul 2>&1
if errorlevel 1 (
    powercfg /setactive SCHEME_MIN >nul 2>&1
    if errorlevel 1 (
        echo         - Skema High Performance tidak tersedia di mesin ini.
    ) else (
        echo         - Power Plan disetel ke High Performance (fallback).
    )
) else (
    echo         - Power Plan disetel ke High Performance.
)
echo.
echo  ==========================================================================
echo   [OK] OPTIMASI SELESAI (v%CURRENT_VER%)
echo  ==========================================================================
echo   - Beban disk HDD berkurang (SysMain/Search/telemetry dimatikan).
echo   - Efek transparansi dan visual berat Windows dimatikan.
echo   - Layanan database POS, printer, dan jaringan tidak diubah.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto OPTIMIZE_FALLBACK
choice /C YN /N /M "  Restart Explorer sekarang agar efek visual langsung aktif? [Y/N]: "
set "EXP_ERR=!errorlevel!"
if "!EXP_ERR!"=="2" goto MENU
if "!EXP_ERR!"=="1" goto RESTART_EXPLORER
goto MENU

:OPTIMIZE_FALLBACK
set /p "EXP_CHOICE=  Restart Explorer sekarang? [Y/N]: "
if /i "!EXP_CHOICE!"=="Y" goto RESTART_EXPLORER
goto MENU

:RESTART_EXPLORER
echo   [*] Me-restart Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start "" "%SystemRoot%\explorer.exe"
echo   [OK] Explorer dijalankan ulang.
timeout /t 1 /nobreak >nul
goto MENU

:: ======================================================================
:: 2. KEMBALIKAN KE STANDAR DEFAULT WINDOWS
:: ======================================================================
:RESTORE_DEFAULTS
cls
echo.
echo  ==========================================================================
echo   MENGEMBALIKAN PENGATURAN KE STANDAR DEFAULT WINDOWS
echo  ==========================================================================
echo.
echo   Tindakan ini akan mengaktifkan kembali layanan SysMain, Search,
echo   efek transparansi, dan pengaturan visual standar Windows.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_FALLBACK
choice /C YN /N /M "  Lanjutkan reset ke default? [Y/N]: "
set "RST_ERR=!errorlevel!"
if "!RST_ERR!"=="2" goto MENU
goto RESTORE_GO

:RESTORE_FALLBACK
set /p "RST_CHOICE=  Lanjutkan reset ke default? [Y/N]: "
if /i not "!RST_CHOICE!"=="Y" goto MENU

:RESTORE_GO
echo.
echo   [] Mengembalikan Service...
call :ManageService WSearch auto
call :ManageService SysMain auto
call :ManageService DiagTrack auto
call :ManageService DoSvc demand
call :ManageService BITS demand
echo   [] Mengembalikan Hibernasi ^& NTFS...
powercfg /h on >nul 2>&1 || echo         - powercfg tidak mendukung hibernasi di mesin ini.
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 2 >nul 2>&1 || echo         - fsutil tidak tersedia atau gagal.
echo   [] Mengembalikan Efek Transparansi ^& Visual...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1 || echo         - Key Personalize tidak tersedia, dilewati.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /f >nul 2>&1 || echo         - Policy DWM tidak ada atau tidak dapat dihapus.
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1 || echo         - Key DWM tidak tersedia, dilewati.
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1 || echo         - Key AlwaysHibernateThumbnails tidak ada.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1 || echo         - Key VisualEffects tidak tersedia, dilewati.
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f >nul 2>&1 || echo         - UserPreferencesMask tidak tersedia, dilewati.
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f >nul 2>&1 || echo         - DragFullWindows tidak tersedia, dilewati.
echo         - Efek transparansi dan visual Windows dikembalikan jika memungkinkan.
echo   [] Mengembalikan Visual ^& Power Plan...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1 || echo         - MenuShowDelay tidak tersedia, dilewati.
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1 || echo         - MinAnimate tidak tersedia, dilewati.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1 || echo         - BackgroundAccessApplications tidak tersedia, dilewati.
powercfg /setactive %GUID_BALANCED% >nul 2>&1
if errorlevel 1 powercfg /setactive SCHEME_BALANCED >nul 2>&1
echo.
echo   [OK] Seluruh pengaturan telah dikembalikan ke standar default Windows.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_EXP_FALLBACK
choice /C YN /N /M "  Restart Explorer sekarang? [Y/N]: "
set "REX_ERR=!errorlevel!"
if "!REX_ERR!"=="1" goto RESTART_EXPLORER
goto MENU

:RESTORE_EXP_FALLBACK
set /p "REX_CHOICE=  Restart Explorer sekarang? [Y/N]: "
if /i "!REX_CHOICE!"=="Y" goto RESTART_EXPLORER
goto MENU

:: ======================================================================
:: 3. DIAGNOSTIK RINGKAS
:: ======================================================================
:DIAGNOSTICS
cls
echo.
echo  ==========================================================================
echo   DIAGNOSTIK RINGKAS SISTEM
echo  ==========================================================================
echo.
echo   [Identitas PC]
echo     - Nama PC     : %COMPUTERNAME%
echo     - Pengguna    : %USERNAME%
echo     - Win Build   : %WIN_BUILD%
echo.
echo   [Tipe Disk]
call :DetectDisk
if not defined DISK_TYPE set "DISK_TYPE=HDD"
echo     - Tipe        : !DISK_TYPE!
echo.
echo   [Status Efek Transparansi]
set "TRANSP_STATUS=Tidak Diketahui"
for /f "tokens=3" %%A in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency 2^>nul ^| findstr /i "EnableTransparency"') do set "TRANSP_STATUS=%%A"
if /i "!TRANSP_STATUS!"=="0x0" set "TRANSP_STATUS=MATI [Dioptimasi]"
if /i "!TRANSP_STATUS!"=="0x1" set "TRANSP_STATUS=AKTIF [Default]"
echo     - Transparansi : !TRANSP_STATUS!
echo.
echo   [Status Layanan Kunci]
call :ShowSvc SysMain
call :ShowSvc WSearch
call :ShowSvc DiagTrack
call :ShowSvc BITS
call :ShowSvc dmwappushservice
call :ShowSvc DoSvc
echo.
echo   [Status Drive Sistem]
set "FREE_GB="
if not "!HAS_PS!"=="1" goto FREE_SHOW
for /f "delims=" %%A in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { $n=$env:SystemDrive.Substring(0,1); [math]::Round((Get-PSDrive -Name $n).Free / 1GB, 1) } catch {}" 2^>nul') do set "FREE_GB=%%A"
:FREE_SHOW
if defined FREE_GB (
    echo     - Sisa ruang %SystemDrive% : !FREE_GB! GB
) else (
    echo     - Sisa ruang %SystemDrive% : tidak terdeteksi
)
echo.
echo   [Power Plan Aktif]
for /f "delims=" %%A in ('powercfg /getactivescheme 2^>nul') do echo     - %%A
echo.
echo  ==========================================================================
pause
goto MENU

:: ======================================================================
:: SUB-ROUTINES
:: ======================================================================
:DetectDisk
set "DISK_TYPE=HDD"
set "SYS_MEDIA="
if not "!HAS_PS!"=="1" goto DETECT_WMI
for /f "delims=" %%A in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { $letter=$env:SystemDrive.Substring(0,1); $p=Get-Partition -DriveLetter $letter -ErrorAction Stop; $d=Get-Disk -Number $p.DiskNumber -ErrorAction Stop; $d.MediaType } catch {}" 2^>nul') do (
    set "CAND=%%A"
    if defined CAND (
        echo !CAND! | findstr /i "SSD HDD Unspecified SCM" >nul && set "SYS_MEDIA=!CAND!"
    )
)
if defined SYS_MEDIA (
    echo !SYS_MEDIA! | findstr /i "SSD" >nul && set "DISK_TYPE=SSD"
    echo !SYS_MEDIA! | findstr /i "HDD" >nul && set "DISK_TYPE=HDD"
    exit /b 0
)

:DETECT_WMI
set "SAW_SSD="
set "SAW_HDD="
for /f "tokens=*" %%A in ('wmic diskdrive get MediaType 2^>nul ^| findstr /i /v "MediaType"') do (
    set "WMT=%%A"
    set "WMT=!WMT: =!"
    if /i "!WMT!"=="SSD" set "SAW_SSD=1"
    if /i "!WMT!"=="FixedHardDiskMedia" set "SAW_HDD=1"
    if /i "!WMT!"=="ExternalHardDiskMedia" set "SAW_HDD=1"
    if /i "!WMT!"=="RemovableMedia" set "SAW_HDD=1"
)
if defined SAW_SSD (
    set "DISK_TYPE=SSD"
) else (
    set "DISK_TYPE=HDD"
)
exit /b 0

:VerToNum
set "OUTVAR=%~1"
set "RAW=%~2"
set "RAW=!RAW:v=!"
set "RAW=!RAW:V=!"
set "RAW=!RAW: =!"
set "P1=0"
set "P2=0"
set "P3=0"
set "P4=0"
for /f "tokens=1-4 delims=." %%A in ("!RAW!") do (
    if not "%%A"=="" set "P1=%%A"
    if not "%%B"=="" set "P2=%%B"
    if not "%%C"=="" set "P3=%%C"
    if not "%%D"=="" set "P4=%%D"
)
set /a "!OUTVAR!=!P1!*1000000+!P2!*10000+!P3!*100+!P4!" 2>nul
exit /b 0

:ManageService
set "SVC=%~1"
set "ACTION=%~2"
%SystemRoot%\System32\sc.exe query "%SVC%" >nul 2>&1
if errorlevel 1 (
    echo         - %SVC% : Tidak tersedia di versi Windows ini
    exit /b 0
)
if /i "%ACTION%"=="disabled" (
    %SystemRoot%\System32\sc.exe stop "%SVC%" >nul 2>&1
    %SystemRoot%\System32\sc.exe config "%SVC%" start= disabled >nul 2>&1
    echo         - %SVC% : Disabled
) else if /i "%ACTION%"=="demand" (
    %SystemRoot%\System32\sc.exe config "%SVC%" start= demand >nul 2>&1
    echo         - %SVC% : Manual
) else if /i "%ACTION%"=="auto" (
    %SystemRoot%\System32\sc.exe config "%SVC%" start= auto >nul 2>&1
    %SystemRoot%\System32\sc.exe start "%SVC%" >nul 2>&1
    echo         - %SVC% : Aktif
)
exit /b 0

:CleanSafeTemp
set "TARGET_DIR=%~1"
if not exist "%TARGET_DIR%" exit /b 0
del /f /q "%TARGET_DIR%\*.tmp" >nul 2>&1
del /f /q "%TARGET_DIR%\*.bak" >nul 2>&1
del /f /q "%TARGET_DIR%\*.old" >nul 2>&1
del /f /q "%TARGET_DIR%\*.dmp" >nul 2>&1
del /f /q "%TARGET_DIR%\*.log" >nul 2>&1
exit /b 0

:ShowSvc
set "ST=Tidak ada"
for /f "tokens=3 delims=: " %%A in ('%SystemRoot%\System32\sc.exe query "%~1" 2^>nul ^| findstr /i "STATE"') do set "ST=%%A"
echo     - %~1 : !ST!
exit /b 0

:: ======================================================================
:: KELUAR
:: ======================================================================
:QUIT
endlocal
exit /b 0
