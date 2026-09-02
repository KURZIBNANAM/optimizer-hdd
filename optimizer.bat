@echo off
setlocal EnableExtensions enabledelayedexpansion

title OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 (v2)
mode con: cols=76 lines=32
color 0b

:: Cek Hak Akses Administrator
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
    pause
    exit /b
)

:: ======================================================================
:: BAGIAN AUTO UPDATE
:: ======================================================================
set "CURRENT_VER=2.0"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"

cls
echo  ======================================================================
echo    MEMERIKSA PEMBARUAN SISTEM...
echo  ======================================================================
echo.

set "REMOTE_VER="
:: Ambil baris pertama version.txt secara silent
for /f "tokens=* delims=" %%A in ('curl -s -m 3 "%VER_URL%" 2^>nul') do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

:: Jika offline, gagal curl, atau versinya persis sama -> langsung ke menu
if "%REMOTE_VER%"=="" goto menu
if "%REMOTE_VER%"=="%CURRENT_VER%" goto menu

:: Jika versi terdeteksi beda (dan bukan respon error 404 dari GitHub)
echo %REMOTE_VER% | findstr /i "404 Not Found" >nul
if %errorlevel% equ 0 goto menu

echo    [!] Versi baru terdeteksi: v%REMOTE_VER% (Versi terpasang: v%CURRENT_VER%)
echo    [*] Mengunduh pembaruan, mohon tunggu...

curl -s -m 15 -o "%temp%\new_optimizer.bat" "%UPDATE_URL%"

if exist "%temp%\new_optimizer.bat" (
    echo    [OK] Unduhan selesai. Memperbarui skrip...
    
    :: Buat helper script untuk menimpa file ini dan meluncurkan ulang via cmd
    (
        echo @echo off
        echo timeout /t 1 /nobreak ^>nul
        echo copy /y "%temp%\new_optimizer.bat" "%~f0" ^>nul
        echo del /f /q "%temp%\new_optimizer.bat" ^>nul
        echo start "" cmd /c "%~f0"
        echo exit
    ) > "%temp%\self_updater.bat"
    
    start "" "%temp%\self_updater.bat"
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
echo    [1] Jalankan Optimasi (Service + Cache + Registry Aman)
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
:: BAGIAN 1: NONAKTIFKAN / KURANGI SERVICE BERAT
:: ---------------------------------------------------------------
echo  [*] Mengoptimalkan service latar belakang...

:: 1. Windows Search
net stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
call :Check %errorlevel% "Windows Search dinonaktifkan, beban disk berkurang." "Windows Search tidak bisa dinonaktifkan"

:: 2. Telemetri (DiagTrack)
net stop "DiagTrack" >nul 2>&1
sc config "DiagTrack" start= disabled >nul 2>&1
call :Check %errorlevel% "Telemetri Windows dinonaktifkan." "Telemetri tidak bisa dinonaktifkan"

:: 3. BITS -> diset "Manual" (bukan disabled total)
sc config "bits" start= demand >nul 2>&1
call :Check %errorlevel% "BITS diset ke Manual, aman untuk Windows Update dan antivirus." "BITS gagal diubah"

:: 4. Delivery Optimization
net stop "DoSvc" >nul 2>&1
sc config "DoSvc" start= disabled >nul 2>&1
call :Check %errorlevel% "Delivery Optimization dinonaktifkan." "Delivery Optimization tidak bisa dinonaktifkan"

:: 5. WAP Push Service
net stop "dmwappushservice" >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
call :Check %errorlevel% "WAP Push Service dinonaktifkan." "WAP Push Service tidak bisa dinonaktifkan"

:: ---------------------------------------------------------------
:: BAGIAN 2: PENGATURAN SISTEM & REGISTRY AMAN
:: ---------------------------------------------------------------
echo.
echo  [*] Menerapkan tweak sistem dan registry...

:: 6. Hibernasi (otomatis ikut mematikan Fast Startup)
powercfg /h off >nul 2>&1
call :Check %errorlevel% "Hibernasi dinonaktifkan, hiberfil.sys dihapus, Fast Startup ikut nonaktif." "Hibernasi gagal dinonaktifkan"

:: 7. Visual Effects
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
call :Check %errorlevel% "Visual Effects diset ke Best Performance." "Visual Effects gagal diubah"

:: 8. Menu Show Delay
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
call :Check %errorlevel% "Respon animasi menu dipercepat, MenuShowDelay 0." "MenuShowDelay gagal diubah"

:: 9. Timeout Shutdown dan Kill Task
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f >nul 2>&1
call :Check %errorlevel% "AutoEndTasks diaktifkan, task macet ditutup otomatis." "AutoEndTasks gagal diterapkan"

reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 1000 /f >nul 2>&1
call :Check %errorlevel% "HungAppTimeout dipercepat ke 1000ms." "HungAppTimeout gagal diterapkan"

reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 2000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillAppTimeout dipercepat ke 2000ms." "WaitToKillAppTimeout gagal diterapkan"

reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillServiceTimeout dipercepat ke 2000ms." "WaitToKillServiceTimeout gagal diterapkan"

:: 10. NTFS Last Access Time
fsutil behavior set disablelastaccess 1 >nul 2>&1
call :Check %errorlevel% "NTFS Last Access Time dinonaktifkan." "NTFS Last Access Time gagal diubah"

:: 11. Background Apps
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
call :Check %errorlevel% "Aplikasi latar belakang dinonaktifkan." "Background Apps gagal diubah"

:: ---------------------------------------------------------------
:: BAGIAN 3: PEMBERSIHAN CACHE & FILE SEMENTARA
:: ---------------------------------------------------------------
echo.
echo  [*] Membersihkan file sampah dan cache...
del /s /f /q "%temp%\*.*" >nul 2>&1
for /d %%D in ("%temp%\*") do rd /s /q "%%D" >nul 2>&1
del /s /f /q "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo       [OK] Cache temporary user dan Windows dibersihkan.

:: 13. Flush DNS
ipconfig /flushdns >nul 2>&1
echo       [OK] DNS Cache berhasil di-flush.

:: 14. Power Plan
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
call :Check %errorlevel% "Skema daya diatur ke High Performance." "Power plan gagal diubah"

echo.
echo  ======================================================================
echo                             OPTIMASI BERHASIL!
echo  ======================================================================
echo    Aplikasi dibuat oleh : Khairullah Irfansyah, S.Kom (BM JAYA 2)
echo    Kontak Support / WA  : +62 857 7506 3033
echo  ----------------------------------------------------------------------
echo    Catatan Sistem:
echo    - Layanan POS, Printer, dan Remote Desktop tetap aktif normal.
echo    - SysMain tetap berjalan untuk mempercepat cache aplikasi di HDD.
echo    - Pilih menu [2] kapan saja untuk mengembalikan semua ke default.
echo  ======================================================================
echo.
pause
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
pause

echo  === MULAI RESTORE KE DEFAULT ===
echo.
echo  [*] Mengembalikan konfigurasi service ke Automatic...

:: WSearch
sc config "WSearch" start= auto >nul 2>&1
net start "WSearch" >nul 2>&1
call :Check %errorlevel% "Windows Search dikembalikan ke Auto dan berjalan." "Windows Search gagal dipulihkan"

:: DiagTrack
sc config "DiagTrack" start= auto >nul 2>&1
net start "DiagTrack" >nul 2>&1
call :Check %errorlevel% "Telemetri dikembalikan ke Auto dan berjalan." "Telemetri gagal dipulihkan"

:: BITS
sc config "bits" start= auto >nul 2>&1
net start "bits" >nul 2>&1
call :Check %errorlevel% "BITS dikembalikan ke Auto dan berjalan." "BITS gagal dipulihkan"

:: DoSvc
sc config "DoSvc" start= auto >nul 2>&1
net start "DoSvc" >nul 2>&1
call :Check %errorlevel% "Delivery Optimization dikembalikan ke Auto dan berjalan." "Delivery Optimization gagal dipulihkan"

:: dmwappushservice
sc config "dmwappushservice" start= auto >nul 2>&1
net start "dmwappushservice" >nul 2>&1
call :Check %errorlevel% "WAP Push Service dikembalikan ke Auto dan berjalan." "WAP Push Service gagal dipulihkan"

echo.
echo  [*] Mengembalikan konfigurasi registry dan daya...

:: Hibernasi On
powercfg /h on >nul 2>&1
call :Check %errorlevel% "Hibernasi diaktifkan kembali." "Hibernasi gagal diaktifkan"

:: Visual Effects
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
call :Check %errorlevel% "Visual Effects dikembalikan ke Let Windows Choose, default asli." "Visual Effects gagal dipulihkan"

:: MenuShowDelay Default
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
call :Check %errorlevel% "MenuShowDelay dikembalikan ke 400ms." "MenuShowDelay gagal dipulihkan"

:: Shutdown Timeout Default
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 0 /f >nul 2>&1
call :Check %errorlevel% "AutoEndTasks dikembalikan ke default." "AutoEndTasks gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 5000 /f >nul 2>&1
call :Check %errorlevel% "HungAppTimeout dikembalikan ke 5000ms." "HungAppTimeout gagal dipulihkan"

reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 20000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillAppTimeout dikembalikan ke 20000ms." "WaitToKillAppTimeout gagal dipulihkan"

reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 5000 /f >nul 2>&1
call :Check %errorlevel% "WaitToKillServiceTimeout dikembalikan ke 5000ms." "WaitToKillServiceTimeout gagal dipulihkan"

:: NTFS Last Access Time Default
fsutil behavior set disablelastaccess 0 >nul 2>&1
call :Check %errorlevel% "NTFS Last Access Time diaktifkan kembali." "NTFS Last Access Time gagal dipulihkan"

:: Background Apps Default
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
call :Check %errorlevel% "Izin Background Apps diaktifkan kembali." "Background Apps gagal dipulihkan"

:: Power Plan Balanced
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
call :Check %errorlevel% "Skema daya dikembalikan ke Balanced, Rekomendasi." "Power plan gagal dipulihkan"

echo.
echo  ======================================================================
echo                      PEMULIHAN PENGATURAN SELESAI!
echo  ======================================================================
echo    Aplikasi dibuat oleh : Khairullah Irfansyah, S.Kom (BM JAYA 2)
echo    Kontak Support / WA  : +62 857 7506 3033
echo  ----------------------------------------------------------------------
echo    Seluruh service dan registry telah dikembalikan ke pengaturan awal
echo    Windows tanpa perlu reboot.
echo  ======================================================================
echo.
pause
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
