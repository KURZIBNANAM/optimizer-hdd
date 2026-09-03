@echo off
setlocal EnableExtensions enabledelayedexpansion

title OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 (v1.0)
mode con: cols=76 lines=32
color 0b

:: ======================================================================
:: CEK HAK AKSES ADMINISTRATOR
:: ======================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    cls
    echo.
    echo  ======================================================================
    echo    [!] PERINGATAN: HAK AKSES ADMINISTRATOR DIBUTUHKAN
    echo  ======================================================================
    echo.
    echo    Skrip ini memerlukan hak akses penuh untuk mengelola service.
    echo    Silakan klik kanan file ini lalu pilih "Run as administrator".
    echo.
    echo  ======================================================================
    echo.
    pause >nul
    exit /b
)

:: ======================================================================
:: BAGIAN AUTO UPDATE
:: ======================================================================
set "CURRENT_VER=1.1"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"

cls
echo  ======================================================================
echo    MEMERIKSA PEMBARUAN SISTEM...
echo  ======================================================================
echo.

:: Validasi apakah curl tersedia di Windows
where curl >nul 2>&1
if %errorlevel% neq 0 (
    echo    [!] Utilitas curl tidak ditemukan. Melanjutkan dengan versi saat ini...
    timeout /t 2 /nobreak >nul
    goto menu
)

set "REMOTE_VER="
for /f "usebackq tokens=*" %%A in (`curl -s -m 3 "%VER_URL%" 2^>nul`) do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

if "%REMOTE_VER%"=="" goto menu

:: Abaikan jika respon 404 dari GitHub
echo %REMOTE_VER% | findstr /i "404 Not Found" >nul
if %errorlevel% equ 0 goto menu

:: Komparasi versi presisi tanpa bug substring findstr
if /i "%REMOTE_VER%"=="%CURRENT_VER%" goto menu
if /i "%REMOTE_VER%"=="v%CURRENT_VER%" goto menu

echo    [!] Versi baru terdeteksi: %REMOTE_VER% (Versi terpasang: v%CURRENT_VER%)
echo    [*] Mengunduh pembaruan, mohon tunggu...

curl -s -m 15 -o "%temp%\new_optimizer.bat" "%UPDATE_URL%" >nul 2>&1

if exist "%temp%\new_optimizer.bat" (
    echo    [OK] Unduhan selesai. Memperbarui skrip...
    
    (
        echo @echo off
        echo timeout /t 2 /nobreak ^>nul
        echo copy /y "%temp%\new_optimizer.bat" "%~f0" ^>nul
        echo del /f /q "%temp%\new_optimizer.bat" ^>nul
        echo start "" "%~f0"
        echo exit
    ) > "%temp%\self_updater.bat"
    
    start "" /min "%temp%\self_updater.bat"
    exit /b
) else (
    echo    [!] Gagal mengunduh file update. Melanjutkan versi lama...
    timeout /t 2 /nobreak >nul
    goto menu
)

:menu
cls
echo  ======================================================================
echo     SYSTEM OPTIMIZER WINDOWS 10 (HDD KASIR) - BM JAYA 2 - v%CURRENT_VER%
echo  ======================================================================
echo    Pengembang : Khairullah Irfansyah, S.Kom
echo    Unit       : BM JAYA 2
echo    Kontak/WA  : +62 857 7506 3033
echo  ======================================================================
echo.
echo    PILIHAN MENU:
echo.
echo    [1] Jalankan Optimasi (HDD Ramah POS + Anti-Disk 100%%)
echo    [2] Kembalikan Pengaturan Awal (Default Windows)
echo    [3] Keluar dari Program
echo.
echo  ======================================================================
choice /C 123 /N /M "  Masukkan pilihan Anda [1/2/3] : "

if errorlevel 3 goto exit
if errorlevel 2 goto restore
if errorlevel 1 goto optimize

:optimize
cls
echo  ======================================================================
echo            PROSES OPTIMASI SISTEM BERJALAN (MODE HDD KASIR)
echo  ======================================================================
echo.
echo  === MULAI OPTIMASI ===

:: ---------------------------------------------------------------
:: BAGIAN 1: NONAKTIFKAN SERVICE PEMBEBAN HDD
:: ---------------------------------------------------------------
echo  [*] Mengoptimalkan service latar belakang...

net stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
call :Check %errorlevel% "Windows Search dinonaktifkan, index disk dihentikan." "Windows Search gagal diubah"

net stop "DiagTrack" >nul 2>&1
sc config "DiagTrack" start= disabled >nul 2>&1
call :Check %errorlevel% "Telemetri Windows dinonaktifkan." "Telemetri gagal diubah"

:: SysMain (Superfetch) dimatikan agar tidak membaca ribuan file acak saat booting HDD
net stop "SysMain" >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
call :Check %errorlevel% "SysMain dinonaktifkan (Mencegah Disk 100%% bottleneck)." "SysMain gagal diubah"

sc config "bits" start= demand >nul 2>&1
call :Check %errorlevel% "BITS diset ke Manual (On-Demand)." "BITS gagal diubah"

net stop "DoSvc" >nul 2>&1
sc config "DoSvc" start= disabled >nul 2>&1
call :Check %errorlevel% "Delivery Optimization dinonaktifkan." "Delivery Optimization gagal diubah"

net stop "dmwappushservice" >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
call :Check %errorlevel% "WAP Push Service dinonaktifkan." "WAP Push Service gagal diubah"

:: ---------------------------------------------------------------
:: BAGIAN 2: PENGATURAN SISTEM & REGISTRY RAMAH KASIR
:: ---------------------------------------------------------------
echo.
echo  [*] Menerapkan tweak sistem dan registry...

powercfg /h off >nul 2>&1
call :Check %errorlevel% "Hibernasi dinonaktifkan (Mencegah beban Fast Startup HDD)." "Hibernasi gagal dinonaktifkan"

:: Efek visual dipangkas, tetapi Font Smoothing (ClearType) tetap aktif agar layar kasir nyaman dibaca
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
call :Check %errorlevel% "Visual Effects dioptimasi tanpa merusak kejernihan teks kasir." "Visual Effects gagal diubah"

reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
call :Check %errorlevel% "Respon animasi menu dipercepat (MenuShowDelay 0)." "MenuShowDelay gagal diubah"

:: Batas aman penutupan aplikasi: AutoEndTasks diset 0 agar database tidak crash saat shutdown
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 5000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 5000 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 5000 /f >nul 2>&1
call :Check %errorlevel% "Shutdown timeout diatur ke batas aman database transaksi (5000ms)." "Timeout shutdown gagal diubah"

fsutil behavior set disablelastaccess 1 >nul 2>&1
call :Check %errorlevel% "NTFS Last Access Time dinonaktifkan (Mengurangi write overhead)." "NTFS Last Access Time gagal diubah"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
call :Check %errorlevel% "Aplikasi latar belakang dinonaktifkan." "Background Apps gagal diubah"

:: ---------------------------------------------------------------
:: BAGIAN 3: PEMBERSIHAN CACHE & FILE SEMENTARA
:: ---------------------------------------------------------------
echo.
echo  [*] Membersihkan file sampah dan cache...
del /s /f /q "%temp%\*.*" >nul 2>&1
for /d %%D in ("%temp%\*") do rd /s /q "%%D" >nul 2>&1
del /s /f /q "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo       [OK] Cache temporary user dan Windows dibersihkan.

ipconfig /flushdns >nul 2>&1
echo       [OK] DNS Cache berhasil di-flush.

powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
call :Check %errorlevel% "Skema daya diatur ke High Performance." "Power plan gagal diubah"

echo.
echo  ======================================================================
echo                             OPTIMASI BERHASIL!
echo  ======================================================================
echo    Aplikasi dibuat oleh : Khairullah Irfansyah, S.Kom (BM JAYA 2)
echo    Kontak Support / WA  : +62 857 7506 3033
echo  ----------------------------------------------------------------------
echo    Catatan Sistem Kasir:
echo    - Database kasir aman dari penutupan paksa saat shutdown.
echo    - SysMain dan Windows Search dinonaktifkan untuk memangkas Disk 100%%.
echo    - Layanan POS, Printer Kasir, dan Jaringan tetap bekerja normal.
echo  ======================================================================
echo.
echo    Tekan tombol apa saja untuk kembali ke menu utama...
pause >nul
goto menu

:restore
cls
echo  ======================================================================
echo               MENGEMBALIKAN SISTEM KE PENGATURAN DEFAULT
echo  ======================================================================
echo.
echo    [!] PERHATIAN:
echo        - Cache temporary yang terhapus tidak dapat dikembalikan (aman).
echo        - Service, Registry, dan Power Plan akan diset ke bawaan Windows.
echo.
echo  ======================================================================
echo.
echo    Tekan tombol apa saja untuk melanjutkan...
pause >nul

echo  === MULAI RESTORE KE DEFAULT ===
echo.
echo  [*] Mengembalikan konfigurasi service ke default asli...

sc config "WSearch" start= delayed-auto >nul 2>&1
net start "WSearch" >nul 2>&1
call :Check %errorlevel% "Windows Search dikembalikan ke Automatic (Delayed)." "Windows Search gagal dipulihkan"

sc config "DiagTrack" start= auto >nul 2>&1
net start "DiagTrack" >nul 2>&1
call :Check %errorlevel% "Telemetri dikembalikan ke Auto." "Telemetri gagal dipulihkan"

sc config "SysMain" start= auto >nul 2>&1
net start "SysMain" >nul 2>&1
call :Check %errorlevel% "SysMain dikembalikan ke Auto." "SysMain gagal dipulihkan"

sc config "bits" start= demand >nul 2>&1
call :Check %errorlevel% "BITS dikembalikan ke Manual (Default asli)." "BITS gagal dipulihkan"

sc config "DoSvc" start= delayed-auto >nul 2>&1
call :Check %errorlevel% "Delivery Optimization dikembalikan ke Automatic (Delayed)." "Delivery Optimization gagal dipulihkan"

sc config "dmwappushservice" start= demand >nul 2>&1
call :Check %errorlevel% "WAP Push Service dikembalikan ke Manual (Default asli)." "WAP Push Service gagal dipulihkan"

echo.
echo  [*] Mengembalikan konfigurasi registry dan daya...

powercfg /h on >nul 2>&1
call :Check %errorlevel% "Hibernasi diaktifkan kembali." "Hibernasi gagal diaktifkan"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
call :Check %errorlevel% "Visual Effects dikembalikan ke pengaturan default Windows." "Visual Effects gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
call :Check %errorlevel% "MenuShowDelay dikembalikan ke 400ms." "MenuShowDelay gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 0 /f >nul 2>&1
call :Check %errorlevel% "AutoEndTasks dikembalikan ke default." "AutoEndTasks gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 5000 /f >nul 2>&1
call :Check %errorlevel% "HungAppTimeout dikembalikan ke 5000ms." "HungAppTimeout gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 20000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillAppTimeout dikembalikan ke 20000ms." "WaitToKillAppTimeout gagal dipulihkan"

reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 5000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillServiceTimeout dikembalikan ke 5000ms." "WaitToKillServiceTimeout gagal dipulihkan"

fsutil behavior set disablelastaccess 0 >nul 2>&1
call :Check %errorlevel% "NTFS Last Access Time diaktifkan kembali." "NTFS Last Access Time gagal dipulihkan"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
call :Check %errorlevel% "Izin Background Apps diaktifkan kembali." "Background Apps gagal dipulihkan"

powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
call :Check %errorlevel% "Skema daya dikembalikan ke Balanced." "Power plan gagal dipulihkan"

echo.
echo  ======================================================================
echo                      PEMULIHAN PENGATURAN SELESAI!
echo  ======================================================================
echo    Aplikasi dibuat oleh : Khairullah Irfansyah, S.Kom (BM JAYA 2)
echo    Kontak Support / WA  : +62 857 7506 3033
echo  ----------------------------------------------------------------------
echo    Seluruh service dan registry telah dikembalikan ke pengaturan awal.
echo  ======================================================================
echo.
echo    Tekan tombol apa saja untuk kembali ke menu utama...
pause >nul
goto menu

:exit
cls
exit /b

:Check
if %1 equ 0 (
    echo        [OK] %2
) else (
    echo        [!!] %3
)
exit /b
