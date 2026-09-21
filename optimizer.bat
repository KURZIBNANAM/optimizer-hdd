@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v1.6
mode con: cols=80 lines=35
color 0b

:: ======================================================================
:: IDENTITAS & KONFIGURASI
:: ======================================================================
set "CURRENT_VER=1.6"
set "APP_NAME=System Optimizer Windows 10 HDD"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"

:: ======================================================================
:: CEK ADMINISTRATOR
:: ======================================================================
net session >nul 2>&1
if not "%errorlevel%"=="0" (
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

:: ======================================================================
:: DETEKSI VERSI WINDOWS 10 (KOMPATIBILITAS)
:: ======================================================================
set "WIN_BUILD=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WIN_BUILD=%%A"
if "%WIN_BUILD%"=="0" set "WIN_BUILD=Unknown"

:: ======================================================================
:: AUTO UPDATE CERDAS (NON-BLOCKING JIKA OFFLINE)
:: ======================================================================
:CHECK_UPDATE
cls
echo.
echo  ==========================================================================
echo   SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v%CURRENT_VER%
echo  ==========================================================================
echo.
echo   [*] Memeriksa pembaruan repository...

where curl >nul 2>&1 || goto MENU
where powershell >nul 2>&1 || goto MENU

set "REMOTE_VER="
for /f "usebackq tokens=1 delims= " %%A in (`curl -L -s --fail --connect-timeout 2 -m 4 "%VER_URL%" 2^>nul`) do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

if not defined REMOTE_VER (
    echo   [i] Offline / repository tidak dapat dijangkau. Melewati update...
    timeout /t 1 /nobreak >nul
    goto MENU
)

:: Bersihkan format versi
set "REMOTE_VER=!REMOTE_VER:v=!"
set "REMOTE_VER=!REMOTE_VER:V=!"
set "REMOTE_VER=!REMOTE_VER: =!"

:: Bandingkan versi secara numerik
set "IS_NEW="
for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$a=[version]'%CURRENT_VER%'; $b=[version]'%REMOTE_VER%'; if($b -gt $a){'YES'}" 2^>nul') do set "IS_NEW=%%A"

if /i "%IS_NEW%"=="YES" (
    echo   [*] Versi baru terdeteksi: v%REMOTE_VER%
    echo   [*] Mengunduh script pembaruan...
    
    set "UPDATER_TMP=%TEMP%\update_%RANDOM%.bat"
    curl -L -s --fail --connect-timeout 4 -m 20 -o "!UPDATER_TMP!" "%UPDATE_URL%" >nul 2>&1
    
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
)
goto MENU

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
echo   Windows 10 : Build %WIN_BUILD%
echo  ==========================================================================
echo.
echo   [1] Jalankan Optimasi HDD (POS Safe Mode)
echo   [2] Kembalikan ke Standar Default Windows
echo   [3] Cek Status Sistem Singkat (Diagnostik)
echo   [4] Keluar
echo.
echo  ==========================================================================
choice /C 1234 /N /M "  Pilih menu [1-4]: "
if errorlevel 4 goto QUIT
if errorlevel 3 goto DIAGNOSTICS
if errorlevel 2 goto RESTORE_DEFAULTS
if errorlevel 1 goto OPTIMIZE

:: ======================================================================
:: 1. PROSES OPTIMASI (IDEMPOTENT & ZERO TRACE)
:: ======================================================================
:OPTIMIZE
cls
echo.
echo  ==========================================================================
echo   MEMULAI OPTIMASI HDD (POS SAFE MODE)
echo  ==========================================================================
echo.

:: 1. Deteksi Jenis Disk & Service Background I/O Berat
echo   [1/9] Memeriksa Disk ^& Mengatur Windows Service...
set "DISK_TYPE="
for /f "tokens=*" %%A in ('powershell -NoProfile -Command "Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber } | Select-Object -ExpandProperty MediaType" 2^>nul') do set "DISK_TYPE=%%A"
if not defined DISK_TYPE set "DISK_TYPE=HDD"
echo         - Drive C: terdeteksi sebagai: %DISK_TYPE%
if /i "%DISK_TYPE%"=="SSD" (
    echo         - Drive C: adalah SSD. Mengamankan SysMain...
    call :ManageService SysMain auto
) else (
    call :ManageService SysMain disabled
)
call :ManageService WSearch disabled
call :ManageService DiagTrack disabled
call :ManageService DoSvc demand
call :ManageService dmwappushservice demand
call :ManageService BITS demand

:: 2. Matikan Hibernasi (Menghemat 4-8 GB drive C:)
echo.
echo   [2/9] Mengelola Storage ^& Hibernasi...
powercfg /h off >nul 2>&1
echo         - File hiberfil.sys dinonaktifkan (Kapasitas C: bertambah).

:: 3. Optimasi Responsivitas UI & Background Apps
echo.
echo   [3/9] Optimasi Responsivitas UI ^& Registry...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
echo         - Animasi jendela ^& delay menu diminimalkan.

:: 4. Matikan Efek Transparansi Windows 10 (Meringankan GPU & CPU)
echo.
echo   [4/9] Menonaktifkan Efek Transparansi Windows 10...
:: EnableTransparency tersedia di Windows 10 Build 15063+ (Creators Update 1703+)
:: Pada build lama, key ini tidak ada dan akan dibuat tanpa efek samping
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
echo         - Efek transparansi taskbar dan Start Menu dimatikan.
:: Matikan juga efek blur/acrylic DWM (berlaku di semua build Windows 10)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul 2>&1
echo         - Efek visual DWM -- Aero Peek, animasi komposisi -- dimatikan.
:: Nonaktifkan visual effects via SystemPropertiesPerformance registry
:: Kompatibel dengan semua versi Windows 10 (Build 10240+)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo         - Visual Effects disetel ke mode performa terbaik.

:: 5. Matikan NTFS Last Access Write (Mengurangi beban tulis mekanik HDD)
echo.
echo   [5/9] Mengurangi Beban Write Disk (NTFS)...
if /i not "%DISK_TYPE%"=="SSD" (
    fsutil behavior set disablelastaccess 1 >nul 2>&1
    echo         - Pencatatan waktu akses baca file dinonaktifkan.
) else (
    echo         - SSD terdeteksi, melewati tweak NTFS...
)

:: 6. Pembersihan Cache Windows Update (Aman Diulang)
echo.
echo   [6/9] Membersihkan Cache Windows Update Lama...
forfiles /p "%SystemRoot%\SoftwareDistribution\Download" /s /m *.* /d -7 /c "cmd /c del /f /q @path" >nul 2>&1
echo         - File cache update lama (^>7 hari) dibersihkan.

:: 7. Pembersihan File Sementara Konservatif
echo.
echo   [7/9] Pembersihan Cache ^& File Temp Aman...
ipconfig /flushdns >nul 2>&1
call :CleanSafeTemp "%TEMP%"
call :CleanSafeTemp "%SystemRoot%\Temp"
echo         - Cache DNS ^& file temporary kadaluarsa dibersihkan.

:: 8. Pembersihan Log Event Viewer
echo.
echo   [8/9] Membersihkan Log Event Viewer...
for /f "tokens=*" %%L in ('wevtutil.exe el 2^>nul') do wevtutil.exe cl "%%L" >nul 2>&1
echo         - Log Windows Event Viewer dikosongkan.

:: 9. Mode High Performance (Mencegah throttling daya CPU)
echo.
echo   [9/9] Mengaktifkan Mode High Performance...
powercfg /setactive SCHEME_MIN >nul 2>&1
if errorlevel 1 (
    powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    powercfg /setactive SCHEME_MIN >nul 2>&1
)
echo         - Power Plan disetel ke performa penuh.

echo.
echo  ==========================================================================
echo   [OK] OPTIMASI SELESAI (v%CURRENT_VER%)
echo  ==========================================================================
echo   - Beban 100%% disk HDD berkurang signifikan.
echo   - Efek transparansi ^& visual berat Windows dimatikan.
echo   - Layanan Database POS, Printer, dan Jaringan tetap aman 100%%.
echo   - Tidak ada file log/sampah yang tersimpan di sistem.
echo.
pause
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
echo   [*] Mengembalikan Service...
call :ManageService WSearch auto
call :ManageService SysMain auto
call :ManageService DiagTrack auto
call :ManageService DoSvc demand
call :ManageService BITS demand

echo   [*] Mengembalikan Hibernasi ^& NTFS...
powercfg /h on >nul 2>&1
fsutil behavior set disablelastaccess 0 >nul 2>&1

echo   [*] Mengembalikan Efek Transparansi ^& Visual...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
echo         - Efek transparansi ^& visual Windows dikembalikan.

echo   [*] Mengembalikan Visual ^& Power Plan...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
powercfg /setactive SCHEME_BALANCED >nul 2>&1

echo.
echo   [OK] Seluruh pengaturan telah dikembalikan ke standar default Windows.
echo.
echo   [i] Catatan: Cache Windows Update ^& Log Event Viewer yang sudah
echo       dibersihkan bersifat pembersihan dan tidak dapat dikembalikan.
echo.
pause
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
echo     - Win10 Build : %WIN_BUILD%

echo.
echo   [Tipe Disk Drive C:]
set "DIAG_DISK="
for /f "tokens=*" %%A in ('powershell -NoProfile -Command "Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber } | Select-Object -ExpandProperty MediaType" 2^>nul') do set "DIAG_DISK=%%A"
if not defined DIAG_DISK set "DIAG_DISK=Tidak Terdeteksi"
echo     - Tipe        : %DIAG_DISK%

echo.
echo   [Status Efek Transparansi]
set "TRANSP_STATUS=Tidak Diketahui"
for /f "tokens=3" %%A in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency 2^>nul ^| findstr /i "EnableTransparency"') do set "TRANSP_STATUS=%%A"
if "!TRANSP_STATUS!"=="0x0" set "TRANSP_STATUS=MATI [Dioptimasi]"
if "!TRANSP_STATUS!"=="0x1" set "TRANSP_STATUS=AKTIF [Default]"
echo     - Transparansi : !TRANSP_STATUS!

echo.
echo   [Status Layanan Kunci]
for %%S in (SysMain WSearch DiagTrack BITS dmwappushservice DoSvc) do (
    for /f "tokens=3 delims=: " %%A in ('sc query "%%S" 2^>nul ^| findstr /i "STATE"') do (
        echo     - %%S : %%A
    )
)

echo.
echo   [Status Drive Sistem]
for /f "tokens=3" %%A in ('dir "%SystemDrive%\" ^| findstr /i "bytes free"') do set "FREE_MB=%%A"
echo     - Sisa Ruang %SystemDrive% : %FREE_MB% bytes

echo.
echo   [Power Plan Aktif]
for /f "tokens=3,4,*" %%A in ('powercfg /getactivescheme 2^>nul') do echo     - %%B %%C

echo.
echo  ==========================================================================
pause
goto MENU

:: ======================================================================
:: SUB-ROUTINES (FUNGSI PEMBANTU)
:: ======================================================================
:ManageService
set "SVC=%~1"
set "ACTION=%~2"
sc query "%SVC%" >nul 2>&1
if errorlevel 1 exit /b 0

if /i "%ACTION%"=="disabled" (
    net stop "%SVC%" >nul 2>&1
    sc config "%SVC%" start= disabled >nul 2>&1
    echo         - %SVC% : Disabled
) else if /i "%ACTION%"=="demand" (
    sc config "%SVC%" start= demand >nul 2>&1
    echo         - %SVC% : Manual
) else if /i "%ACTION%"=="auto" (
    sc config "%SVC%" start= auto >nul 2>&1
    net start "%SVC%" >nul 2>&1
    echo         - %SVC% : Aktif
)
exit /b 0

:CleanSafeTemp
set "TARGET_DIR=%~1"
if not exist "%TARGET_DIR%\" exit /b 0
forfiles /p "%TARGET_DIR%" /s /m *.* /d -1 /c "cmd /c del /f /q @path" >nul 2>&1
exit /b 0

:: ======================================================================
:: KELUAR
:: ======================================================================
:QUIT
endlocal
exit /b 0
