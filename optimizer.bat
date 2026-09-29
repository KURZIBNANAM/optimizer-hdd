@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v1.8

:: ======================================================================
:: IDENTITAS & KONFIGURASI
:: ======================================================================
set "CURRENT_VER=1.8"
set "APP_NAME=System Optimizer Windows 10 HDD"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"
set "GUID_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "GUID_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"

:: ======================================================================
:: CEK ADMINISTRATOR + AUTO UAC FIX (Kompatibel Semua Versi Windows)
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
        echo   Script ini memerlukan hak administrator untuk mengelola service dan disk.
        echo   Klik kanan file ini, lalu pilih: "Run as administrator"
        echo.
        pause
        exit /b 1
    )
    echo.
    echo   [*] Meminta hak Administrator via UAC...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
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
:: DETEKSI KETERSEDIAAN CURL / POWERSHELL DOWNLOAD
:: ======================================================================
set "HAS_CURL=0"
set "HAS_PS=0"
where curl.exe >nul 2>&1 && set "HAS_CURL=1"
where powershell.exe >nul 2>&1 && set "HAS_PS=1"

:: ======================================================================
:: AUTO UPDATE (NON-BLOCKING JIKA OFFLINE/WINDOWS LAMA)
:: ======================================================================
:CHECK_UPDATE
if "!HAS_PS!"=="0" goto MENU
cls
echo.
echo  ==========================================================================
echo   SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v%CURRENT_VER%
echo  ==========================================================================
echo.
echo   [] Memeriksa pembaruan repository...
set "REMOTE_VER="

:: -- Coba curl dulu (Win10 1709+), fallback ke PowerShell (semua Win10) --
if "!HAS_CURL!"=="1" (
    for /f "usebackq tokens=1 delims= " %%A in (`curl.exe -L -s --fail --connect-timeout 2 -m 4 "%VER_URL%" 2^>nul`) do (
        if not defined REMOTE_VER set "REMOTE_VER=%%A"
    )
) else (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadString('%VER_URL%').Trim() } catch {}" 2^>nul') do (
        if not defined REMOTE_VER set "REMOTE_VER=%%A"
    )
)

if not defined REMOTE_VER (
    echo   [i] Offline / repository tidak dapat dijangkau. Melewati update...
    timeout /t 1 /nobreak >nul
    goto MENU
)
set "REMOTE_VER=!REMOTE_VER:v=!"
set "REMOTE_VER=!REMOTE_VER:V=!"
set "REMOTE_VER=!REMOTE_VER: =!"
set "IS_NEW="
for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$a=[version]'%CURRENT_VER%';$r='%REMOTE_VER%'.Trim^(^).Trim^([char]0xFEFF^); try { $b=[version]$r; if($b -gt$a){'YES'} } catch {}" 2^>nul') do set "IS_NEW=%%A"
if /i not "!IS_NEW!"=="YES" goto MENU
echo   [] Versi baru terdeteksi: v!REMOTE_VER!
echo   [*] Mengunduh script pembaruan...
set "UPDATER_TMP=%TEMP%\update_%RANDOM%.bat"

:: -- Download: curl atau PowerShell fallback --
if "!HAS_CURL!"=="1" (
    curl.exe -L -s --fail --connect-timeout 4 -m 20 -o "!UPDATER_TMP!" "%UPDATE_URL%" >nul 2>&1
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%UPDATE_URL%','!UPDATER_TMP!') } catch {}" >nul 2>&1
)

if not exist "!UPDATER_TMP!" goto SKIP_UPDATE
findstr /i /c:":MENU" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
findstr /i /c:"Khairullah Irfansyah" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
findstr /i /c:"CURRENT_VER" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
echo   [OK] Validasi 3-titik berhasil. Memasang versi baru...
set "SELF_RUNNER=%TEMP%\replacer_%RANDOM%.bat"
(
echo @echo off
echo timeout /t 1 /nobreak ^>nul
echo copy /y "!UPDATER_TMP!" "%~f0" ^>nul
echo del /f /q "!UPDATER_TMP!" ^>nul
echo start "" "%~f0"
echo del /f /q "%%~f0" ^>nul
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
echo   SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 [v%CURRENT_VER%]
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
echo  ==========================================================================
choice /C 1234 /N /M "  Pilih menu [1-4]: "
if errorlevel 255 goto MENU_FALLBACK
if errorlevel 4 goto QUIT
if errorlevel 3 goto DIAGNOSTICS
if errorlevel 2 goto RESTORE_DEFAULTS
if errorlevel 1 goto OPTIMIZE

:MENU_FALLBACK
set /p "MENU_CHOICE=  Pilih menu [1-4]: "
if "!MENU_CHOICE!"=="4" goto QUIT
if "!MENU_CHOICE!"=="3" goto DIAGNOSTICS
if "!MENU_CHOICE!"=="2" goto RESTORE_DEFAULTS
if "!MENU_CHOICE!"=="1" goto OPTIMIZE
goto MENU

:: ======================================================================
:: 1. PROSES OPTIMASI (SILENT NO LOG)
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
echo         - Drive %SystemDrive% terdeteksi sebagai: !DISK_TYPE!
if /i "!DISK_TYPE!"=="SSD" (
    echo         - Drive sistem adalah SSD. SysMain tetap Auto.
    call :ManageService SysMain auto
    call :ManageService Superfetch auto
) else (
    call :ManageService SysMain disabled
    call :ManageService Superfetch disabled
)
call :ManageService WSearch disabled
call :ManageService DiagTrack disabled
call :ManageService DoSvc demand
call :ManageService dmwappushservice demand
call :ManageService BITS demand
echo.
echo   [2/9] Mengelola Storage ^& Hibernasi...
powercfg /h off >nul 2>&1
echo         - File hiberfil.sys dinonaktifkan (kapasitas C: bertambah).
echo.
echo   [3/9] Optimasi Responsivitas UI ^& Registry...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
echo         - Delay menu, animasi, dan background apps diminimalkan.
echo.
echo   [4/9] Menonaktifkan Efek Transparansi Windows 10...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo         - Transparansi, Aero Peek, dan Visual Effects mode performa.
echo.
echo   [5/9] Mengurangi Beban Write Disk (NTFS)...
if /i not "!DISK_TYPE!"=="SSD" (
    %SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 1 >nul 2>&1
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
)
if defined WU_RUNNING sc start wuauserv >nul 2>&1
echo         - Cache update di folder Download dibersihkan.
echo.
echo   [7/9] Pembersihan Cache ^& File Temp Aman...
ipconfig /flushdns >nul 2>&1
call :CleanSafeTemp "%TEMP%"
call :CleanSafeTemp "%SystemRoot%\Temp"
echo         - Cache DNS dan file temporary kadaluarsa dibersihkan.
echo.
echo   [8/9] Membersihkan Log Event Viewer...
%SystemRoot%\System32\wevtutil.exe cl Application >nul 2>&1
%SystemRoot%\System32\wevtutil.exe cl System >nul 2>&1
%SystemRoot%\System32\wevtutil.exe cl Setup >nul 2>&1
echo         - Log Application, System, dan Setup dikosongkan.
echo.
echo   [9/9] Mengaktifkan Mode High Performance...
powercfg /setactive %GUID_HIGH% >nul 2>&1
if errorlevel 1 powercfg /setactive SCHEME_MIN >nul 2>&1
if errorlevel 1 (
    echo         - Skema High Performance tidak tersedia di mesin ini.
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
echo   - Beberapa efek UI aktif setelah Explorer di-restart.
echo.
choice /C YN /N /M "  Restart Explorer sekarang agar efek visual langsung aktif? [Y/N]: "
if errorlevel 2 goto MENU
if errorlevel 1 (
    echo   [*] Me-restart Explorer...
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    start "" explorer.exe
    echo   [OK] Explorer dijalankan ulang.
    timeout /t 1 /nobreak >nul
)
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
choice /C YN /N /M "  Lanjutkan reset ke default? [Y/N]: "
if errorlevel 2 goto MENU
echo.
echo   [] Mengembalikan Service...
call :ManageService WSearch auto
call :ManageService SysMain auto
call :ManageService Superfetch auto
call :ManageService DiagTrack auto
call :ManageService DoSvc demand
call :ManageService BITS demand
echo   [] Mengembalikan Hibernasi ^& NTFS...
powercfg /h on >nul 2>&1
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 2 >nul 2>&1
echo   [] Mengembalikan Efek Transparansi ^& Visual...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f >nul 2>&1
echo         - Efek transparansi dan visual Windows dikembalikan.
echo   [] Mengembalikan Visual ^& Power Plan...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
powercfg /setactive %GUID_BALANCED% >nul 2>&1
if errorlevel 1 powercfg /setactive SCHEME_BALANCED >nul 2>&1
echo.
echo   [OK] Seluruh pengaturan telah dikembalikan ke standar default Windows.
echo.
echo   [i] Cache Windows Update dan Log Event Viewer yang sudah
echo       dibersihkan bersifat pembersihan dan tidak dapat dikembalikan.
echo.
choice /C YN /N /M "  Restart Explorer sekarang? [Y/N]: "
if errorlevel 2 goto MENU
if errorlevel 1 (
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    start "" explorer.exe
)
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
set "FREE_BYTES="
for /f "tokens=2 delims==" %%A in ('wmic logicaldisk where "DeviceID='%SystemDrive%'" get FreeSpace /value 2^>nul ^| findstr /i "FreeSpace"') do (
    for /f "delims=" %%B in ("%%A") do set "FREE_BYTES=%%B"
)
if not defined FREE_BYTES set "FREE_BYTES=Tidak terdeteksi"
echo     - Sisa ruang %SystemDrive% : !FREE_BYTES! byte
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
set "SAW_HDD="
set "SAW_SSD="
:: Metode 1: PowerShell Get-PhysicalDisk (Win10 semua versi)
for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk ^| Select-Object -ExpandProperty MediaType" 2^>nul') do (
    set "MT=%%A"
    set "MT=!MT: =!"
    if /i "!MT!"=="HDD" set "SAW_HDD=1"
    if /i "!MT!"=="SSD" set "SAW_SSD=1"
    if /i "!MT!"=="SCM" set "SAW_SSD=1"
)
:: Metode 2: Fallback via WMI jika Get-PhysicalDisk gagal/Unspecified
if not defined SAW_HDD if not defined SAW_SSD (
    for /f "tokens=*" %%A in ('wmic diskdrive get MediaType 2^>nul ^| findstr /i /v "MediaType"') do (
        set "WMT=%%A"
        set "WMT=!WMT: =!"
        if /i "!WMT!"=="FixedHardDiskMedia" set "SAW_HDD=1"
        if /i "!WMT!"=="ExternalHardDiskMedia" set "SAW_HDD=1"
        if /i "!WMT!"=="RemovableMedia" set "SAW_HDD=1"
    )
)
if defined SAW_SSD (
    set "DISK_TYPE=SSD"
) else (
    set "DISK_TYPE=HDD"
)
exit /b 0

:ManageService
set "SVC=%~1"
set "ACTION=%~2"
%SystemRoot%\System32\sc.exe query "%SVC%" >nul 2>&1
if errorlevel 1 exit /b 0
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
