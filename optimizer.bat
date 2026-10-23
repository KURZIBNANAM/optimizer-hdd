@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 (HDD/SSD) - BM JAYA 2 v2.3

:: ======================================================================
:: IDENTITAS & KONFIGURASI
:: Kompatibel: Windows 10 2015 (1507/Build 10240) s/d Terbaru (22H2/19045)
:: Target    : PC Kasir (POS) & PC Kantor/Reguler (Prioritas HDD & SSD)
:: Prinsip   : Zero Log / Aman Sharing Printer / Aman IP Statis
:: ======================================================================
set "SELF_PATH=%~f0"
set "SELF_DIR=%~dp0"
setlocal EnableDelayedExpansion

set "CURRENT_VER=2.3"
set "APP_NAME=System Optimizer Windows 10 (POS & Office)"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"
set "GUID_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "GUID_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"

:: ======================================================================
:: CEK ADMINISTRATOR + AUTO UAC (AMAN KARAKTER SPESIAL & SPASI)
:: ======================================================================
%SystemRoot%\System32\fltmc.exe >nul 2>&1
if errorlevel 1 (
    where powershell.exe >nul 2>&1
    if errorlevel 1 (
        cls
        echo.
        echo ==========================================================================
        echo [!] HAK ADMINISTRATOR DIBUTUHKAN
        echo ==========================================================================
        echo Klik kanan file ini, lalu pilih: "Run as administrator"
        echo.
        pause
        exit /b 1
    )
    echo.
    echo [*] Meminta hak Administrator via UAC...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:SELF_PATH -Verb RunAs } catch { exit 1 }"
    if errorlevel 1 (
        echo.
        echo [!] UAC dibatalkan atau gagal.
        echo Klik kanan file ini, lalu pilih "Run as administrator".
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

pushd "!SELF_DIR!" >nul 2>&1
mode con: cols=88 lines=44 >nul 2>&1
color 0B

:: Bersihkan sisa file updater sementara jika ada dari sesi sebelumnya
del /f /q "%TEMP%\upd_*.bat" "%TEMP%\rep_*.bat" >nul 2>&1

:: ======================================================================
:: DETEKSI VERSI WINDOWS & TOOLS (1507 BUILD 10240 - 22H2 BUILD 19045)
:: ======================================================================
set "WIN_BUILD=Unknown"
set "WIN_VER=Win10"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WIN_BUILD=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^>nul ^| findstr /i "ReleaseId"') do set "WIN_VER=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul ^| findstr /i "DisplayVersion"') do set "WIN_VER=%%A"
if "!WIN_BUILD!"=="10240" if "!WIN_VER!"=="Win10" set "WIN_VER=1507"

set "HAS_CURL=0"
set "HAS_PS=0"
where curl.exe >nul 2>&1 && set "HAS_CURL=1"
where powershell.exe >nul 2>&1 && set "HAS_PS=1"

:: Deteksi awal tipe disk sistem (%SystemDrive%) agar tampil di Menu Utama
call :DetectDisk

:: ======================================================================
:: AUTO UPDATE (ANTI-HANG, ANTI-CACHE, KOMPATIBEL WIN 10 2015-2022+)
:: ======================================================================
:CHECK_UPDATE
if "!HAS_PS!"=="0" if "!HAS_CURL!"=="0" goto MENU
cls
echo.
echo ==========================================================================
echo !APP_NAME! - BM JAYA 2 v!CURRENT_VER!
echo ==========================================================================
echo.
echo [*] Memeriksa pembaruan script...
set "REMOTE_VER="
set "NOCACHE=?t=!RANDOM!!RANDOM!"

if "!HAS_CURL!"=="1" (
    for /f "usebackq tokens=1 delims= " %%A in (`curl.exe -L -s -k --fail --connect-timeout 3 -m 5 "!VER_URL!!NOCACHE!" 2^>nul`) do (
        if not defined REMOTE_VER set "REMOTE_VER=%%A"
    )
)
if not defined REMOTE_VER if "!HAS_PS!"=="1" (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = 3072; $r = [Net.WebRequest]::Create('!VER_URL!!NOCACHE!'); $r.Timeout = 4000; $r.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore); $resp = $r.GetResponse(); $sr = New-Object IO.StreamReader($resp.GetResponseStream()); $sr.ReadToEnd().Trim(); $sr.Close(); $resp.Close() } catch {}" 2^>nul') do (
        if not defined REMOTE_VER set "REMOTE_VER=%%A"
    )
)

if not defined REMOTE_VER goto MENU

:: Bersihkan karakter BOM, huruf, atau spasi gaib (hanya sisakan angka dan titik)
set "CLEAN_VER="
for /f "delims=" %%A in ("!REMOTE_VER!") do set "RAW_STR=%%A"
for /l %%I in (0,1,15) do (
    set "CH=!RAW_STR:~%%I,1!"
    if defined CH (
        for %%C in (0 1 2 3 4 5 6 7 8 9 .) do (
            if "!CH!"=="%%C" set "CLEAN_VER=!CLEAN_VER!%%C"
        )
    )
)
set "REMOTE_VER=!CLEAN_VER!"
if not defined REMOTE_VER goto MENU

set "IS_NEW="
call :VerToNum CUR_NUM "!CURRENT_VER!"
call :VerToNum REM_NUM "!REMOTE_VER!"
if defined REM_NUM if defined CUR_NUM (
    if !REM_NUM! GTR !CUR_NUM! set "IS_NEW=YES"
)

if /i not "!IS_NEW!"=="YES" goto MENU
echo [*] Versi baru terdeteksi: v!REMOTE_VER!
echo [*] Mengunduh pembaruan...
set "UPDATER_TMP=%TEMP%\upd_!RANDOM!.bat"

if "!HAS_CURL!"=="1" (
    curl.exe -L -s -k --fail --connect-timeout 4 -m 15 -o "!UPDATER_TMP!" "!UPDATE_URL!!NOCACHE!" >nul 2>&1
)
if not exist "!UPDATER_TMP!" if "!HAS_PS!"=="1" (
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = 3072; $r = [Net.WebRequest]::Create('!UPDATE_URL!!NOCACHE!'); $r.Timeout = 12000; $r.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore); $resp = $r.GetResponse(); $s = $resp.GetResponseStream(); $fs = [IO.File]::Create('!UPDATER_TMP!'); $s.CopyTo($fs); $fs.Close(); $s.Close(); $resp.Close() } catch {}" >nul 2>&1
)

if not exist "!UPDATER_TMP!" goto SKIP_UPDATE
:: Validasi isi file agar tidak menimpa script dengan halaman error 404/HTML
findstr /i /c:":MENU" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE
findstr /i /c:"CURRENT_VER" "!UPDATER_TMP!" >nul 2>&1 || goto SKIP_UPDATE

echo [OK] Memasang versi baru v!REMOTE_VER!...
set "SELF_RUNNER=%TEMP%\rep_!RANDOM!.bat"
(
echo @echo off
echo timeout /t 1 /nobreak ^>nul
echo copy /y "!UPDATER_TMP!" "!SELF_PATH!" ^>nul 2^>^&1
echo del /f /q "!UPDATER_TMP!" ^>nul 2^>^&1
echo start "" cmd.exe /c ""!SELF_PATH!""
echo ^(goto^) 2^>nul ^& del /f /q "%%~f0" ^>nul 2^>^&1 ^& exit
) > "!SELF_RUNNER!"
popd >nul 2>&1
start "" /min cmd.exe /c ""!SELF_RUNNER!""
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
echo ==========================================================================
echo  !APP_NAME! [v!CURRENT_VER!]
echo  Pengembang : Khairullah Irfansyah, S.Kom
echo  Unit       : BM JAYA 2
echo  Target     : Komputer Kasir ^(POS^) ^& PC Reguler ^(2015 - 2022+^)
echo  Sistem     : Windows 10 !WIN_VER! ^(Build !WIN_BUILD!^) ^| Disk: !DISK_TYPE!
echo ==========================================================================
echo.
echo  [1] Jalankan Optimasi Sistem ^(Otomatis Sesuai !DISK_TYPE! ^& Aman untuk POS^)
echo  [2] Kembalikan ke Standar Default Windows
echo  [3] Cek Status Sistem Singkat ^(Diagnostik^)
echo  [4] Keluar
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto MENU_FALLBACK
choice /C 1234 /N /M " Pilih menu [1-4]: "
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
:: 1. PROSES OPTIMASI (KOMPATIBEL WIN 10 1507-22H2, POS & PC BIASA)
:: ======================================================================
:OPTIMIZE
cls
echo.
echo ==========================================================================
echo  MEMULAI OPTIMASI SISTEM ^(MODE: !DISK_TYPE! - POS ^& PC REGULER SAFE^)
echo ==========================================================================
echo.
echo [1/9] Mengatur Layanan Background ^& Proteksi Sharing Printer...
if /i "!DISK_TYPE!"=="SSD" (
    echo  - Disk adalah SSD: Menjaga SysMain/Superfetch tetap optimal.
    call :ManagePrefetch auto
    call :ManageService WSearch demand
) else (
    echo  - Disk adalah HDD: Mematikan SysMain/Superfetch ^& Indexing agar disk tidak 100%%.
    call :ManagePrefetch disabled
    call :ManageService WSearch disabled
)
call :ManageService DiagTrack disabled
call :ManageService dmwappushservice demand
call :ManageService MapsBroker disabled
call :ManageService WerSvc demand
call :ManageService DoSvc demand
call :ManageService BITS demand
:: Pastikan layanan Sharing Printer & SMB selalu aktif & tidak terganggu
call :ManageService Spooler auto
call :ManageService LanmanServer auto
call :ManageService LanmanWorkstation auto
echo.

echo [2/9] Mengelola Storage ^& Hibernasi...
powercfg -h off >nul 2>&1
echo  - Hibernasi dinonaktifkan ^(hemat ruang GB di %SystemDrive% ^& kurangi beban tulis^).
echo.

echo [3/9] Optimasi Responsivitas UI ^& Memori Aplikasi Latar...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d "2000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d "3000" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo  - Delay menu, aplikasi latar belakang, dan timeout aplikasi macet dioptimalkan.
echo.

echo [4/9] Menonaktifkan Efek Visual Berat ^& Transparansi...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
echo  - Transparansi dan animasi berat telah dimatikan ^(Font tetap halus/tidak pecah^).
echo.

echo [5/9] Mengoptimalkan File System ^(NTFS^)...
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 1 >nul 2>&1
if /i "!DISK_TYPE!"=="SSD" (
    %SystemRoot%\System32\fsutil.exe behavior set DisableDeleteNotify 0 >nul 2>&1
    echo  - LastAccess dimatikan ^& fitur TRIM SSD dipastikan aktif.
) else (
    echo  - Pencatatan waktu akses baca file ^(LastAccess^) dinonaktifkan untuk meringankan HDD.
)
echo.

echo [6/9] Membersihkan Cache Windows Update yang Menumpuk...
%SystemRoot%\System32\sc.exe query wuauserv 2>nul | findstr /i "RUNNING" >nul 2>&1 && (
    echo  - Menghentikan sementara layanan Windows Update...
    %SystemRoot%\System32\net.exe stop wuauserv >nul 2>&1
)
%SystemRoot%\System32\sc.exe query bits 2>nul | findstr /i "RUNNING" >nul 2>&1 && (
    %SystemRoot%\System32\net.exe stop bits >nul 2>&1
)
if exist "%SystemRoot%\SoftwareDistribution\Download\" (
    del /f /q "%SystemRoot%\SoftwareDistribution\Download\*.*" >nul 2>&1
    for /d %%D in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%~fD" >nul 2>&1
)
echo  - Cache unduhan Windows Update selesai dibersihkan.
echo.

echo [7/9] Membersihkan File Temporary ^& Cache DNS ^(Aman untuk IP Statis ^& POS^)...
ipconfig /flushdns >nul 2>&1
call :CleanSafeTemp "%TEMP%"
call :CleanSafeTemp "%SystemRoot%\Temp"
echo  - Cache DNS disegarkan ^(IP Statis 100%% utuh^) ^& file sampah temporary dibersihkan.
echo.

echo [8/9] Mengosongkan Log Event Viewer Utama...
for %%L in (Application System Setup) do (
    %SystemRoot%\System32\wevtutil.exe cl "%%L" >nul 2>&1
)
echo  - Log Application, System, dan Setup telah dikosongkan.
echo.

echo [9/9] Mengatur Power Plan ^& Mencegah Disk/USB Printer Sleep...
powercfg /setactive %GUID_HIGH% >nul 2>&1 || (
    powercfg -duplicatescheme %GUID_HIGH% >nul 2>&1
    powercfg /setactive %GUID_HIGH% >nul 2>&1
)
powercfg /change disk-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-ac 0 >nul 2>&1
:: Nonaktifkan USB Selective Suspend agar koneksi USB Printer Kasir/Scanner tidak pernah putus
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo  - Power Plan High Performance aktif, Disk ^& Port USB Printer disetel Anti-Sleep.
echo.

echo ==========================================================================
echo  [OK] OPTIMASI SELESAI ^(v!CURRENT_VER! - Mode !DISK_TYPE!^)
echo ==========================================================================
echo  - Beban I/O disk dikurangi secara signifikan.
echo  - Sharing Printer ^(Spooler/SMB^), IP Statis LAN, dan Database POS 100%% AMAN.
echo  - Tidak ada file .log atau sampah yang ditinggalkan oleh script ini.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto OPTIMIZE_FALLBACK
choice /C YN /N /M " Restart Explorer sekarang agar efek visual langsung terasa? [Y/N]: "
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
:: 2. KEMBALIKAN KE STANDAR DEFAULT WINDOWS
:: ======================================================================
:RESTORE_DEFAULTS
cls
echo.
echo ==========================================================================
echo  MENGEMBALIKAN PENGATURAN KE STANDAR DEFAULT WINDOWS
echo ==========================================================================
echo.
echo  Tindakan ini akan mengaktifkan kembali layanan Superfetch/SysMain,
echo  Windows Search, efek transparansi, dan pengaturan visual standar.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_FALLBACK
choice /C YN /N /M " Lanjutkan reset ke default? [Y/N]: "
if "!errorlevel!"=="2" goto MENU
goto RESTORE_GO

:RESTORE_FALLBACK
set "RST_CHOICE="
set /p "RST_CHOICE= Lanjutkan reset ke default? [Y/N]: "
if /i not "!RST_CHOICE!"=="Y" goto MENU

:RESTORE_GO
echo.
echo [*] Mengembalikan Layanan Standar Windows...
call :ManagePrefetch auto
call :ManageService WSearch auto
call :ManageService DiagTrack auto
call :ManageService dmwappushservice demand
call :ManageService MapsBroker demand
call :ManageService WerSvc demand
call :ManageService DoSvc demand
call :ManageService BITS demand
call :ManageService Spooler auto

echo [*] Mengembalikan Pengaturan Hibernasi ^& NTFS...
powercfg -h on >nul 2>&1
%SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 2 >nul 2>&1 || %SystemRoot%\System32\fsutil.exe behavior set disablelastaccess 0 >nul 2>&1

echo [*] Mengembalikan Efek Transparansi ^& Visual...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisallowAnimations /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1

echo [*] Mengembalikan Responsivitas Default ^& Power Plan...
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v AutoEndTasks /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d "5000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d "20000" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
powercfg /setactive %GUID_BALANCED% >nul 2>&1 || powercfg /setactive SCHEME_BALANCED >nul 2>&1
powercfg /change disk-timeout-ac 20 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1

echo.
echo [OK] Seluruh pengaturan telah dikembalikan ke standar default Windows.
echo.
where choice.exe >nul 2>&1
if errorlevel 1 goto RESTORE_EXP_FALLBACK
choice /C YN /N /M " Restart Explorer sekarang? [Y/N]: "
if "!errorlevel!"=="1" goto RESTART_EXPLORER
goto MENU

:RESTORE_EXP_FALLBACK
set "REX_CHOICE="
set /p "REX_CHOICE= Restart Explorer sekarang? [Y/N]: "
if /i "!REX_CHOICE!"=="Y" goto RESTART_EXPLORER
goto MENU

:: ======================================================================
:: 3. DIAGNOSTIK RINGKAS
:: ======================================================================
:DIAGNOSTICS
cls
echo.
echo ==========================================================================
echo  DIAGNOSTIK RINGKAS SISTEM
echo ==========================================================================
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
if "!HAS_PS!"=="1" (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -NonInteractive -Command "try { [math]::Round((Get-PSDrive %SystemDrive:~0,1%).Free / 1GB, 2) } catch {}" 2^>nul') do set "FREE_GB=%%A"
)
if defined FREE_GB (
    echo  - Sisa Ruang  : !FREE_GB! GB
) else (
    for /f "tokens=3" %%A in ('dir /-c %SystemDrive%\ 2^>nul ^| findstr /i "bytes free"') do echo  - Sisa Ruang  : %%A Bytes
)
echo.
echo [Status Efek Transparansi]
set "TRANSP_STATUS=Tidak Diketahui"
for /f "tokens=3" %%A in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency 2^>nul ^| findstr /i "EnableTransparency"') do set "TRANSP_STATUS=%%A"
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
echo ==========================================================================
pause
goto MENU

:: ======================================================================
:: SUB-ROUTINES (FUNGSI PENDUKUNG)
:: ======================================================================
:DetectDisk
set "DISK_TYPE=HDD"
set "SYS_DRV=%SystemDrive:~0,1%"
if "!HAS_PS!"=="1" (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -NonInteractive -Command "try { $p = Get-Partition -DriveLetter '!SYS_DRV!' -ErrorAction Stop; $d = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $p.DiskNumber }; if (-not $d) { $d = $p | Get-Disk | Get-PhysicalDisk }; if ($d.MediaType -eq 'SSD' -or $d.SpindleSpeed -eq 0 -or $d.BusType -eq 'NVMe') { 'SSD' } elseif ($d.MediaType -eq 'HDD') { 'HDD' } } catch {}" 2^>nul') do (
        if /i "%%A"=="SSD" set "DISK_TYPE=SSD"
        if /i "%%A"=="HDD" set "DISK_TYPE=HDD"
    )
    if /i "!DISK_TYPE!"=="SSD" exit /b 0
)
where wmic.exe >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ('wmic /namespace:\\root\microsoft\windows\storage path MSFT_PhysicalDisk get MediaType /value 2^>nul ^| findstr "="') do (
        for /f "tokens=1" %%B in ("%%A") do (
            if "%%B"=="4" set "DISK_TYPE=SSD"
        )
    )
    if /i "!DISK_TYPE!"=="SSD" exit /b 0
    for /f "tokens=*" %%A in ('wmic diskdrive get Model 2^>nul') do (
        echo %%A | findstr /i "SSD NVMe Solid" >nul 2>&1 && set "DISK_TYPE=SSD"
    )
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
%SystemRoot%\System32\sc.exe query "%SVC%" >nul 2>&1
if errorlevel 1 exit /b 0

if /i "%ACTION%"=="disabled" (
    %SystemRoot%\System32\sc.exe stop "%SVC%" >nul 2>&1
    %SystemRoot%\System32\sc.exe config "%SVC%" start= disabled >nul 2>&1
    echo  - %SVC% : Dimatikan [Disabled]
    exit /b 0
)
if /i "%ACTION%"=="demand" (
    %SystemRoot%\System32\sc.exe config "%SVC%" start= demand >nul 2>&1
    echo  - %SVC% : Disetel Manual [On-Demand]
    exit /b 0
)
if /i "%ACTION%"=="auto" (
    %SystemRoot%\System32\sc.exe config "%SVC%" start= auto >nul 2>&1
    %SystemRoot%\System32\sc.exe start "%SVC%" >nul 2>&1
    echo  - %SVC% : Diaktifkan [Auto]
    exit /b 0
)
exit /b 0

:CleanSafeTemp
set "TARGET_DIR=%~1"
if not exist "%TARGET_DIR%\" exit /b 0
del /f /q "%TARGET_DIR%\*.tmp" >nul 2>&1
del /f /q "%TARGET_DIR%\*.bak" >nul 2>&1
del /f /q "%TARGET_DIR%\*.old" >nul 2>&1
del /f /q "%TARGET_DIR%\*.dmp" >nul 2>&1
del /f /q "%TARGET_DIR%\*.log" >nul 2>&1
exit /b 0

:ShowSvc
set "ST=Tidak Terpasang"
for /f "tokens=3 delims=: " %%A in ('%SystemRoot%\System32\sc.exe query "%~1" 2^>nul ^| findstr /i "STATE"') do set "ST=%%A"
echo  - %~1 : !ST!
exit /b 0

:VerToNum
set "OUTVAR=%~1"
set "RAW=%~2"
set "P1=0" & set "P2=0" & set "P3=0" & set "P4=0"
for /f "tokens=1-4 delims=." %%A in ("!RAW!") do (
    if not "%%A"=="" set "P1=%%A"
    if not "%%B"=="" set "P2=%%B"
    if not "%%C"=="" set "P3=%%C"
    if not "%%D"=="" set "P4=%%D"
)
:: Hindari bug angka oktal (leading zero seperti 08 / 09) pada set /a
set /a "P1=1000!P1! %% 1000, P2=1000!P2! %% 1000, P3=1000!P3! %% 1000, P4=1000!P4! %% 1000" 2>nul
set /a "!OUTVAR!=!P1!*1000000+!P2!*10000+!P3!*100+!P4!" 2>nul
exit /b 0

:: ======================================================================
:: KELUAR
:: ======================================================================
:QUIT
popd >nul 2>&1
endlocal
exit /b 0
