```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v1.3
mode con: cols=82 lines=38
color 0b

:: ======================================================================
:: SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2
:: VERSION 1.3 - POS SAFE
:: ======================================================================
set "CURRENT_VER=1.3"
set "APP_NAME=System Optimizer Windows 10 HDD"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"

set "BASE_DIR=%ProgramData%\BMJAYA2\SystemOptimizer"
set "BACKUP_DIR=%BASE_DIR%\Backup"
set "LOG_DIR=%BASE_DIR%\Logs"
set "BACKUP_FILE=%BACKUP_DIR%\system_backup.dat"
set "BACKUP_MARKER=%BACKUP_DIR%\backup_complete.flag"
set "LOG_FILE=%LOG_DIR%\optimizer.log"
set "LOCK_FILE=%TEMP%\BMJAYA2_SystemOptimizer.lock"

:: ======================================================================
:: CEK ADMINISTRATOR
:: ======================================================================
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    cls
    echo.
    echo  ==============================================================================
    echo       SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v%CURRENT_VER%
    echo  ==============================================================================
    echo.
    echo       [!!] HAK ADMINISTRATOR DIBUTUHKAN
    echo.
    echo       Klik kanan file BAT ini lalu pilih:
    echo.
    echo                           RUN AS ADMINISTRATOR
    echo.
    echo  ==============================================================================
    pause
    exit /b 1
)

:: ======================================================================
:: CEK INSTANCE GANDA
:: ======================================================================
if exist "%LOCK_FILE%" (
    echo.
    echo  [!!] System Optimizer sedang digunakan oleh instance lain.
    echo.
    echo       Jika tidak ada optimizer lain yang berjalan, hapus file:
    echo       %LOCK_FILE%
    echo.
    pause
    exit /b 1
)

> "%LOCK_FILE%" echo %COMPUTERNAME% - %date% %time%
set "LOCK_CREATED=1"

:: ======================================================================
:: INISIALISASI
:: ======================================================================
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo ============================================================
>>"%LOG_FILE%" echo START - %date% %time%
>>"%LOG_FILE%" echo VERSION: %CURRENT_VER%
>>"%LOG_FILE%" echo COMPUTER: %COMPUTERNAME%

:: ======================================================================
:: INFORMASI WINDOWS
:: ======================================================================
set "WIN_NAME=UNKNOWN"
set "WIN_VERSION="

ver | findstr /i "10.0" >nul 2>&1
if "%errorlevel%"=="0" (
    set "WIN_NAME=Windows 10"
) else (
    set "WIN_NAME=Windows bukan Windows 10"
)

for /f "tokens=2 delims=[]" %%A in ('ver') do set "WIN_VERSION=%%A"

:: ======================================================================
:: CEK POWERSHELL
:: ======================================================================
set "PS_AVAILABLE=0"
where powershell >nul 2>&1
if "%errorlevel%"=="0" set "PS_AVAILABLE=1"

:: ======================================================================
:: AUTO UPDATE
:: ======================================================================
:UPDATE_CHECK
cls
echo.
echo  ==============================================================================
echo                    SYSTEM OPTIMIZER WINDOWS 10 HDD
echo                              BM JAYA 2
echo  ==============================================================================
echo.
echo       Versi terpasang : v%CURRENT_VER%
echo       [*] Memeriksa pembaruan...
echo.

where curl >nul 2>&1
if not "%errorlevel%"=="0" (
    echo       [!] CURL tidak tersedia.
    echo       [i] Pemeriksaan update dilewati.
    >>"%LOG_FILE%" echo [INFO] CURL unavailable - update skipped
    timeout /t 2 /nobreak >nul
    goto menu
)

if "%PS_AVAILABLE%"=="0" (
    echo       [!] PowerShell tidak tersedia.
    echo       [i] Pemeriksaan versi update dilewati.
    >>"%LOG_FILE%" echo [INFO] PowerShell unavailable - version check skipped
    timeout /t 2 /nobreak >nul
    goto menu
)

set "REMOTE_VER="

for /f "usebackq tokens=1 delims= " %%A in (`curl -L -s --fail --connect-timeout 3 -m 5 "%VER_URL%" 2^>nul`) do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

if not defined REMOTE_VER (
    echo       [i] Server update tidak dapat dihubungi.
    echo       [i] Melanjutkan dengan versi saat ini...
    >>"%LOG_FILE%" echo [INFO] Update server unavailable
    timeout /t 2 /nobreak >nul
    goto menu
)

:: Hilangkan awalan v/V
set "REMOTE_VER=!REMOTE_VER:v=!"
set "REMOTE_VER=!REMOTE_VER:V=!"
set "REMOTE_VER=!REMOTE_VER: =!"

:: Validasi format versi
echo(!REMOTE_VER!| findstr /r /x "[0-9][0-9]*\.[0-9][0-9]*\(\.[0-9][0-9]*\)*" >nul 2>&1
if not "%errorlevel%"=="0" (
    echo       [!] Format versi repository tidak valid.
    echo       [i] Update dibatalkan demi keamanan.
    >>"%LOG_FILE%" echo [ERROR] Invalid remote version: %REMOTE_VER%
    timeout /t 2 /nobreak >nul
    goto menu
)

echo       Versi repository : v%REMOTE_VER%
echo.

:: ----------------------------------------------------------------------
:: Bandingkan versi secara numerik menggunakan PowerShell.
:: Hanya update jika REMOTE_VER > CURRENT_VER.
:: ----------------------------------------------------------------------
set "VERSION_STATUS="

for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$a=[version]'%CURRENT_VER%';$b=[version]'%REMOTE_VER%';if($b -gt $a){'NEW'}elseif($b -eq $a){'SAME'}else{'OLD'}" 2^>nul') do set "VERSION_STATUS=%%A"

if /i "%VERSION_STATUS%"=="SAME" (
    echo       [OK] Anda sudah menggunakan versi terbaru.
    >>"%LOG_FILE%" echo [OK] Version current
    timeout /t 2 /nobreak >nul
    goto menu
)

if /i "%VERSION_STATUS%"=="OLD" (
    echo       [OK] Versi lokal lebih baru dari repository.
    echo       [i] Downgrade otomatis tidak diizinkan.
    >>"%LOG_FILE%" echo [INFO] Remote version older - update rejected
    timeout /t 2 /nobreak >nul
    goto menu
)

if /i not "%VERSION_STATUS%"=="NEW" (
    echo       [!!] Versi update tidak dapat diverifikasi.
    echo       [i] Update dibatalkan.
    >>"%LOG_FILE%" echo [ERROR] Version comparison failed
    timeout /t 2 /nobreak >nul
    goto menu
)

echo       [!] Versi baru terdeteksi: v%REMOTE_VER%
echo       [*] Mengunduh pembaruan...
echo.

set "UPDATE_TEMP=%TEMP%\BMJAYA2_optimizer_%RANDOM%_%RANDOM%.bat"

curl -L -s --fail --connect-timeout 5 -m 30 -o "%UPDATE_TEMP%" "%UPDATE_URL%" >nul 2>&1

if not exist "%UPDATE_TEMP%" (
    echo       [!!] Gagal mengunduh pembaruan.
    >>"%LOG_FILE%" echo [ERROR] Update download failed
    timeout /t 2 /nobreak >nul
    goto menu
)

:: ----------------------------------------------------------------------
:: Validasi file update.
:: Tidak cukup hanya mencari CURRENT_VER.
:: ----------------------------------------------------------------------
findstr /i /c:"CURRENT_VER=" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

findstr /i /c:"APP_NAME=" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

findstr /i /c:":menu" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

findstr /i /c:":optimize" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

findstr /i /c:":restore" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

findstr /i /c:":diagnostics" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" goto update_invalid

:: ----------------------------------------------------------------------
:: Pastikan file update memiliki versi yang sama dengan version.txt.
:: ----------------------------------------------------------------------
set "DOWNLOADED_VER="

for /f "tokens=1,* delims==" %%A in ('findstr /i /b /c:"set "CURRENT_VER=" "%UPDATE_TEMP%" 2^>nul') do (
    set "DOWNLOADED_VER=%%B"
)

if not defined DOWNLOADED_VER (
    for /f "tokens=2 delims==" %%A in ('findstr /i /b "set \"CURRENT_VER=" "%UPDATE_TEMP%" 2^>nul') do (
        set "DOWNLOADED_VER=%%~A"
    )
)

set "DOWNLOADED_VER=!DOWNLOADED_VER:"=!"
set "DOWNLOADED_VER=!DOWNLOADED_VER: =!"

if not defined DOWNLOADED_VER goto update_invalid

for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$a=[version]'%DOWNLOADED_VER%';$b=[version]'%REMOTE_VER%';if($a -eq $b){'MATCH'}else{'MISMATCH'}" 2^>nul') do set "UPDATE_VERSION_STATUS=%%A"

if /i not "%UPDATE_VERSION_STATUS%"=="MATCH" goto update_invalid

echo       [OK] File update lolos validasi dasar.
echo       [*] Menyiapkan proses penggantian file...
echo.

set "SELF_UPDATER=%TEMP%\BMJAYA2_self_updater_%RANDOM%_%RANDOM%.bat"
set "TARGET_FILE=%~f0"

(
    echo @echo off
    echo setlocal
    echo timeout /t 2 /nobreak ^>nul
    echo copy /y "%UPDATE_TEMP%" "%TARGET_FILE%" ^>nul 2^>^&1
    echo if errorlevel 1 exit /b 1
    echo del /f /q "%UPDATE_TEMP%" ^>nul 2^>^&1
    echo start "" "%TARGET_FILE%"
    echo del /f /q "%%~f0" ^>nul 2^>^&1
) > "%SELF_UPDATER%"

start "" /min "%SELF_UPDATER%"

>>"%LOG_FILE%" echo [OK] Update prepared: v%REMOTE_VER%
>>"%LOG_FILE%" echo [INFO] Optimizer restarted after update

del /f /q "%LOCK_FILE%" >nul 2>&1
set "LOCK_CREATED=0"

exit /b 0

:update_invalid
echo       [!!] File update tidak valid.
echo       [i] File lama tetap digunakan.
>>"%LOG_FILE%" echo [ERROR] Invalid update package
del /f /q "%UPDATE_TEMP%" >nul 2>&1
timeout /t 2 /nobreak >nul
goto menu

:: ======================================================================
:: MENU UTAMA
:: ======================================================================
:menu
cls
echo.
echo  ==============================================================================
echo       SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 - v%CURRENT_VER%
echo  ==============================================================================
echo       Pengembang : Khairullah Irfansyah, S.Kom
echo       Unit       : BM JAYA 2
echo  ==============================================================================
echo.
echo       SISTEM
echo       ----------------------------------------------------------------------------
echo       Windows    : %WIN_NAME%
echo       Komputer   : %COMPUTERNAME%
echo       System     : %WIN_VERSION%
echo       Backup     : %BACKUP_DIR%
echo.
echo       STATUS BACKUP:
if exist "%BACKUP_MARKER%" (
    echo       [OK] Backup ORIGINAL tersedia.
    echo       [i] Restore akan kembali ke kondisi sebelum optimasi pertama.
) else (
    echo       [--] Backup ORIGINAL belum dibuat.
)
echo.
echo  ------------------------------------------------------------------------------
echo       PILIHAN MENU
echo.
echo       [1] Jalankan Optimasi HDD - POS Safe Mode
echo       [2] Kembalikan Pengaturan Sebelum Optimasi Pertama
echo       [3] Pemeriksaan Sistem
echo       [4] Keluar
echo.
echo  ==============================================================================
choice /C 1234 /N /M "  Masukkan pilihan Anda [1-4] : "
if errorlevel 4 goto exit
if errorlevel 3 goto diagnostics
if errorlevel 2 goto restore
if errorlevel 1 goto optimize

:: ======================================================================
:: OPTIMASI
:: ======================================================================
:optimize
cls
echo.
echo  ==============================================================================
echo                  OPTIMASI WINDOWS 10 HDD - POS SAFE MODE
echo  ==============================================================================
echo.
echo       Target:
echo       - Windows 10
echo       - HDD mekanik
echo       - Komputer kasir / POS
echo       - Mengurangi aktivitas disk background
echo       - Menjaga database, printer dan jaringan
echo.
echo       Catatan:
echo       - Aman dijalankan berulang kali.
echo       - Backup ORIGINAL hanya dibuat satu kali.
echo       - Backup tidak ditimpa oleh optimasi berikutnya.
echo.
echo  ==============================================================================

:: ----------------------------------------------------------------------
:: CEK WINDOWS
:: ----------------------------------------------------------------------
if /i not "%WIN_NAME%"=="Windows 10" (
    echo.
    echo       [!] Sistem ini tidak terdeteksi sebagai Windows 10.
    echo       [i] Optimizer ini dirancang khusus untuk Windows 10.
    echo.
    choice /C YN /N /M "  Tetap lanjutkan? [Y/N] : "
    if errorlevel 2 goto menu
)

:: ----------------------------------------------------------------------
:: DETEKSI MEDIA
:: ----------------------------------------------------------------------
echo.
echo  [*] Mendeteksi media penyimpanan...

set "HDD_FOUND=0"
set "SSD_FOUND=0"
set "MEDIA_DETECTION=UNKNOWN"

where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic diskdrive get MediaType 2>nul | findstr /i "Fixed hard disk" >nul 2>&1
    if "%errorlevel%"=="0" set "HDD_FOUND=1"

    wmic diskdrive get Model 2>nul | findstr /i "SSD NVMe" >nul 2>&1
    if "%errorlevel%"=="0" set "SSD_FOUND=1"
)

if "%SSD_FOUND%"=="1" (
    set "MEDIA_DETECTION=SSD/NVMe"
    echo       [i] SSD/NVMe terdeteksi.
    echo       [i] POS Safe Mode tetap digunakan.
) else if "%HDD_FOUND%"=="1" (
    set "MEDIA_DETECTION=HDD"
    echo       [OK] HDD terdeteksi.
) else (
    echo       [i] Tipe media tidak dapat dipastikan.
    echo       [i] POS Safe Mode tetap digunakan.
)

>>"%LOG_FILE%" echo [INFO] Media: %MEDIA_DETECTION%

:: ----------------------------------------------------------------------
:: CEK RUANG DRIVE
:: ----------------------------------------------------------------------
echo.
echo  [*] Memeriksa ruang drive sistem...

set "FREE_SPACE="
for /f "tokens=3" %%A in ('dir "%SystemDrive%\" ^| findstr /i "bytes free"') do set "FREE_SPACE=%%A"

echo       Drive sistem : %SystemDrive%
if defined FREE_SPACE echo       Ruang kosong : %FREE_SPACE%

:: ----------------------------------------------------------------------
:: BACKUP ORIGINAL
:: ----------------------------------------------------------------------
echo.
echo  [*] Memeriksa backup ORIGINAL...

if exist "%BACKUP_MARKER%" (
    echo       [OK] Backup ORIGINAL sudah tersedia.
    echo       [i] Backup tidak ditimpa.
    echo       [i] Optimasi dapat dijalankan berulang kali.
    goto backup_done
)

if exist "%BACKUP_FILE%" (
    echo       [!] File backup ditemukan tetapi marker tidak ada.
    echo       [i] Backup dianggap tidak lengkap.
    echo       [*] Membuat backup baru.
    del /f /q "%BACKUP_FILE%" >nul 2>&1
)

echo.
echo  [*] Membuat backup konfigurasi ORIGINAL...
echo       Kondisi saat ini akan disimpan sebagai baseline restore.
echo.

> "%BACKUP_FILE%" echo # SYSTEM OPTIMIZER WINDOWS 10 HDD v%CURRENT_VER%
>>"%BACKUP_FILE%" echo # BACKUP TYPE: ORIGINAL
>>"%BACKUP_FILE%" echo # Backup dibuat: %date% %time%
>>"%BACKUP_FILE%" echo # Computer: %COMPUTERNAME%
>>"%BACKUP_FILE%" echo # Format service: SERVICE^|NAME^|START^|DELAYED^|STATE
>>"%BACKUP_FILE%" echo.

call :BackupService WSearch
call :BackupService SysMain
call :BackupService DiagTrack
call :BackupService DoSvc
call :BackupService dmwappushservice
call :BackupService BITS

:: ----------------------------------------------------------------------
:: Backup registry VALUE yang benar-benar diubah.
:: ----------------------------------------------------------------------
call :BackupRegValue "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting"
call :BackupRegValue "HKCU\Control Panel\Desktop\WindowMetrics" "MinAnimate"
call :BackupRegValue "HKCU\Control Panel\Desktop" "FontSmoothing"
call :BackupRegValue "HKCU\Control Panel\Desktop" "MenuShowDelay"
call :BackupRegValue "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled"

:: ----------------------------------------------------------------------
:: Backup Power Plan
:: ----------------------------------------------------------------------
powercfg /getactivescheme > "%BACKUP_DIR%\powerplan.txt" 2>&1

:: ----------------------------------------------------------------------
:: Backup Hibernation
:: ----------------------------------------------------------------------
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled > "%BACKUP_DIR%\hibernate.txt" 2>&1

:: ----------------------------------------------------------------------
:: Backup NTFS behavior
:: ----------------------------------------------------------------------
fsutil behavior query disablelastaccess > "%BACKUP_DIR%\lastaccess.txt" 2>&1

:: ----------------------------------------------------------------------
:: Tandai backup selesai hanya jika file utama tersedia.
:: ----------------------------------------------------------------------
if exist "%BACKUP_FILE%" (
    >"%BACKUP_MARKER%" echo BACKUP COMPLETE
    >>"%BACKUP_MARKER%" echo VERSION=%CURRENT_VER%
    >>"%BACKUP_MARKER%" echo COMPUTER=%COMPUTERNAME%
    >>"%BACKUP_MARKER%" echo DATE=%date% %time%
    echo       [OK] Backup ORIGINAL berhasil dibuat.
    >>"%LOG_FILE%" echo [OK] Original backup created
) else (
    echo       [!!] Backup gagal dibuat.
    >>"%LOG_FILE%" echo [ERROR] Original backup creation failed
    echo.
    echo       Optimasi dibatalkan demi keamanan.
    pause
    goto menu
)

:backup_done

>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo ============================================================
>>"%LOG_FILE%" echo OPTIMIZATION STARTED - %date% %time%
>>"%LOG_FILE%" echo COMPUTER: %COMPUTERNAME%
>>"%LOG_FILE%" echo VERSION: %CURRENT_VER%

echo.
echo  ==============================================================================
echo                              MULAI OPTIMASI
echo  ==============================================================================

:: ======================================================================
:: SERVICE
:: ======================================================================
echo.
echo  [BAGIAN 1] SERVICE BACKGROUND
echo  ----------------------------------------------------------------------------

echo  [1/6] Windows Search...
call :SetService WSearch disabled
echo.

echo  [2/6] SysMain...
call :SetService SysMain disabled
echo.

echo  [3/6] DiagTrack...
call :SetService DiagTrack disabled
echo.

echo  [4/6] Delivery Optimization...
call :SetService DoSvc demand
echo.

echo  [5/6] WAP Push Service...
call :SetService dmwappushservice demand
echo.

echo  [6/6] Background Intelligent Transfer Service...
call :SetService BITS demand

:: ======================================================================
:: SYSTEM & UI
:: ======================================================================
echo.
echo  [BAGIAN 2] SYSTEM & UI
echo  ----------------------------------------------------------------------------

echo  [1/6] Hibernation...
powercfg /h off >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Hibernation dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] Hibernation off
) else (
    echo       [!!] Hibernation gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] Hibernation
)

echo.
echo  [2/6] Visual Effects...
set "REG_OK=1"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
if errorlevel 1 set "REG_OK=0"

reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
if errorlevel 1 set "REG_OK=0"

reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
if errorlevel 1 set "REG_OK=0"

if "%REG_OK%"=="1" (
    echo       [OK] Visual Effects dioptimalkan.
    >>"%LOG_FILE%" echo [OK] Visual Effects
) else (
    echo       [!!] Sebagian Visual Effects gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] Visual Effects partial failure
)

echo.
echo  [3/6] MenuShowDelay...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] MenuShowDelay = 0 ms.
    >>"%LOG_FILE%" echo [OK] MenuShowDelay
) else (
    echo       [!!] MenuShowDelay gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] MenuShowDelay
)

echo.
echo  [4/6] Shutdown Timeout...
echo       [OK] WaitToKillAppTimeout tidak diubah.
echo       [OK] WaitToKillServiceTimeout tidak diubah.
echo       [OK] Database/POS diberikan shutdown normal.
>>"%LOG_FILE%" echo [OK] Shutdown timeout untouched

echo.
echo  [5/6] NTFS Last Access...
fsutil behavior set disablelastaccess 1 >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] NTFS Last Access Update dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] NTFS last access disabled
) else (
    echo       [!!] NTFS Last Access gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] NTFS last access
)

echo.
echo  [6/6] Background Apps...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Background Apps dibatasi.
    >>"%LOG_FILE%" echo [OK] Background Apps disabled
) else (
    echo       [!!] Background Apps gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] Background Apps
)

:: ======================================================================
:: CLEANUP
:: ======================================================================
echo.
echo  [BAGIAN 3] CLEANUP KONSERVATIF
echo  ----------------------------------------------------------------------------

echo  [1/4] User TEMP...
call :CleanOldTemp "%TEMP%" 1
echo.

echo  [2/4] Windows TEMP...
call :CleanOldTemp "%SystemRoot%\Temp" 1
echo.

echo  [3/4] DNS Cache...
ipconfig /flushdns >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] DNS Cache berhasil di-flush.
    >>"%LOG_FILE%" echo [OK] DNS flush
) else (
    echo       [!!] DNS Cache gagal di-flush.
    >>"%LOG_FILE%" echo [ERROR] DNS flush
)

echo.
echo  [4/4] Recycle Bin...
echo       [OK] Recycle Bin tidak dihapus paksa.
>>"%LOG_FILE%" echo [OK] Recycle Bin untouched

:: ======================================================================
:: POWER PLAN
:: ======================================================================
echo.
echo  [BAGIAN 4] POWER PLAN
echo  ----------------------------------------------------------------------------
echo  [*] Mengaktifkan High Performance...

powercfg /setactive SCHEME_MIN >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] High Performance diaktifkan.
    >>"%LOG_FILE%" echo [OK] High Performance
) else (
    echo       [!!] High Performance tidak tersedia / gagal diaktifkan.
    >>"%LOG_FILE%" echo [ERROR] High Performance
)

:: ======================================================================
:: DISK MAINTENANCE
:: ======================================================================
echo.
echo  [BAGIAN 5] DISK MAINTENANCE
echo  ----------------------------------------------------------------------------

echo  [1/3] Status disk...
where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic diskdrive get Model,Status 2>nul
) else (
    echo       [i] WMIC tidak tersedia.
    echo       [i] Pemeriksaan detail disk dilewati.
)

echo.
echo  [2/3] File system...
fsutil dirty query %SystemDrive% >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Status file system dapat diperiksa.
    >>"%LOG_FILE%" echo [OK] File system status readable
) else (
    echo       [!!] Status file system tidak dapat dibaca.
    >>"%LOG_FILE%" echo [ERROR] File system status
)

echo.
echo  [3/3] Defragmentasi...
echo       [INFO] Defragmentasi tidak dipaksa.
echo       [INFO] Windows Optimize Drives tetap menangani maintenance.
>>"%LOG_FILE%" echo [INFO] Defrag not forced

:: ======================================================================
:: SELESAI
:: ======================================================================
>>"%LOG_FILE%" echo OPTIMIZATION FINISHED - %date% %time%

echo.
echo  ==============================================================================
echo                            OPTIMASI SELESAI
echo  ==============================================================================
echo.
echo       SYSTEM OPTIMIZER WINDOWS 10 HDD v%CURRENT_VER%
echo.
echo       [OK] Windows Search          : Disabled
echo       [OK] SysMain                 : Disabled
echo       [OK] Telemetry               : Reduced
echo       [OK] Delivery Optimization   : Manual
echo       [OK] WAP Push Service        : Manual
echo       [OK] BITS                    : Manual
echo       [OK] Background Apps         : Reduced
echo       [OK] Visual Effects          : Optimized
echo       [OK] NTFS                    : Optimized
echo       [OK] DNS Cache               : Flushed
echo       [OK] TEMP                    : Conservative Cleanup
echo       [OK] Power Plan              : High Performance
echo.
echo  ------------------------------------------------------------------------------
echo       DATABASE / POS SAFETY
echo.
echo       [OK] Shutdown timeout tidak dipangkas.
echo       [OK] Tidak ada kill paksa database.
echo       [OK] Printer tidak disentuh.
echo       [OK] Network adapter tidak disentuh.
echo       [OK] Defragmentasi tidak dipaksa.
echo       [OK] Backup ORIGINAL tetap aman.
echo.
echo       Backup:
echo       %BACKUP_FILE%
echo.
echo       Log:
echo       %LOG_FILE%
echo.
echo       [!] Restart Windows disarankan setelah optimasi.
echo       [i] Optimizer dapat dijalankan kembali tanpa membuat
echo           backup baru.
echo  ==============================================================================
echo.
pause
goto menu

:: ======================================================================
:: RESTORE
:: ======================================================================
:restore
cls
echo.
echo  ==============================================================================
echo                    RESTORE KONFIGURASI ORIGINAL
echo  ==============================================================================
echo.
echo       Restore akan mengembalikan:
echo       - Service yang diubah
echo       - Registry value yang diubah
echo       - Hibernation
echo       - NTFS Last Access
echo       - Power Plan
echo.
echo       Catatan:
echo       Backup yang digunakan adalah kondisi ORIGINAL sebelum
echo       optimasi pertama, bukan kondisi sebelum eksekusi terakhir.
echo.
echo  ==============================================================================

if not exist "%BACKUP_MARKER%" (
    echo.
    echo       [!!] Backup ORIGINAL tidak ditemukan.
    echo.
    echo       Restore dibatalkan demi keamanan.
    echo.
    pause
    goto menu
)

if not exist "%BACKUP_FILE%" (
    echo.
    echo       [!!] File backup utama tidak ditemukan.
    echo       [i] Restore dibatalkan.
    echo.
    pause
    goto menu
)

echo.
echo       Backup ditemukan:
echo       %BACKUP_FILE%
echo.
choice /C YN /N /M "  Lanjutkan Restore? [Y/N] : "
if errorlevel 2 goto menu

echo.
echo  ==============================================================================
echo                              MULAI RESTORE
echo  ==============================================================================

:: ======================================================================
:: RESTORE SERVICE
:: ======================================================================
echo.
echo  [BAGIAN 1] RESTORE SERVICE
echo  ----------------------------------------------------------------------------

call :RestoreService WSearch
call :RestoreService SysMain
call :RestoreService DiagTrack
call :RestoreService DoSvc
call :RestoreService dmwappushservice
call :RestoreService BITS

:: ======================================================================
:: RESTORE REGISTRY
:: ======================================================================
echo.
echo  [BAGIAN 2] RESTORE REGISTRY
echo  ----------------------------------------------------------------------------

call :RestoreRegValue "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting"
call :RestoreRegValue "HKCU\Control Panel\Desktop\WindowMetrics" "MinAnimate"
call :RestoreRegValue "HKCU\Control Panel\Desktop" "FontSmoothing"
call :RestoreRegValue "HKCU\Control Panel\Desktop" "MenuShowDelay"
call :RestoreRegValue "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled"

:: ======================================================================
:: RESTORE HIBERNATION
:: ======================================================================
echo.
echo  [BAGIAN 3] RESTORE HIBERNATION
echo  ----------------------------------------------------------------------------
call :RestoreHibernate

:: ======================================================================
:: RESTORE NTFS
:: ======================================================================
echo.
echo  [BAGIAN 4] RESTORE NTFS
echo  ----------------------------------------------------------------------------
call :RestoreLastAccess

:: ======================================================================
:: RESTORE POWER PLAN
:: ======================================================================
echo.
echo  [BAGIAN 5] RESTORE POWER PLAN
echo  ----------------------------------------------------------------------------
call :RestorePowerPlan

>>"%LOG_FILE%" echo RESTORE FINISHED - %date% %time%

echo.
echo  ==============================================================================
echo                              RESTORE SELESAI
echo  ==============================================================================
echo.
echo       [OK] Service
echo       [OK] Registry
echo       [OK] Hibernation
echo       [OK] NTFS
echo       [OK] Power Plan
echo.
echo       Backup ORIGINAL TIDAK dihapus.
echo       Anda masih dapat menjalankan optimasi kembali.
echo.
echo       [!] Restart Windows disarankan agar seluruh perubahan diterapkan.
echo  ==============================================================================
echo.
pause
goto menu

:: ======================================================================
:: DIAGNOSTICS
:: ======================================================================
:diagnostics
cls
echo.
echo  ==============================================================================
echo                             SYSTEM DIAGNOSTICS
echo  ==============================================================================
echo.
echo  [1] INFORMASI WINDOWS
echo  ----------------------------------------------------------------------------
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"
echo.

echo  [2] CPU
echo  ----------------------------------------------------------------------------
where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors /format:list 2>nul
) else (
    echo       [i] WMIC tidak tersedia.
)

echo.
echo  [3] RAM
echo  ----------------------------------------------------------------------------
where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic computersystem get TotalPhysicalMemory /format:list 2>nul
) else (
    echo       [i] WMIC tidak tersedia.
)

echo.
echo  [4] DISK
echo  ----------------------------------------------------------------------------
where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic diskdrive get Model,InterfaceType,MediaType,Size,Status 2>nul
) else (
    echo       [i] WMIC tidak tersedia pada sistem ini.
)

echo.
echo  [5] DRIVE SISTEM
echo  ----------------------------------------------------------------------------
where wmic >nul 2>&1
if "%errorlevel%"=="0" (
    wmic logicaldisk where "DeviceID='%SystemDrive%'" get DeviceID,FreeSpace,Size 2>nul
) else (
    echo       [i] WMIC tidak tersedia.
)

echo.
echo  [6] SERVICE
echo  ----------------------------------------------------------------------------
call :ShowService WSearch
call :ShowService SysMain
call :ShowService DiagTrack
call :ShowService DoSvc
call :ShowService dmwappushservice
call :ShowService BITS

echo.
echo  [7] POWER PLAN
echo  ----------------------------------------------------------------------------
powercfg /getactivescheme

echo.
echo  [8] NTFS LAST ACCESS
echo  ----------------------------------------------------------------------------
fsutil behavior query disablelastaccess

echo.
echo  [9] HIBERNATION
echo  ----------------------------------------------------------------------------
powercfg /a

echo.
echo  [10] BACKUP
echo  ----------------------------------------------------------------------------
if exist "%BACKUP_MARKER%" (
    echo       [OK] Backup ORIGINAL tersedia.
    echo       %BACKUP_FILE%
) else (
    echo       [--] Backup ORIGINAL belum dibuat.
)

echo.
echo  [11] OPTIMIZER LOCK
echo  ----------------------------------------------------------------------------
if exist "%LOCK_FILE%" (
    echo       [OK] Instance optimizer sedang aktif.
) else (
    echo       [OK] Tidak ada lock aktif.
)

echo.
echo  [12] LOG
echo  ----------------------------------------------------------------------------
echo       %LOG_FILE%

echo.
echo  ==============================================================================
pause
goto menu

:: ======================================================================
:: SET SERVICE
:: ======================================================================
:SetService
set "SERVICE=%~1"
set "TARGET_START=%~2"

sc query "%SERVICE%" >nul 2>&1
if errorlevel 1 (
    echo       [i] %SERVICE% tidak tersedia pada Windows ini.
    >>"%LOG_FILE%" echo [INFO] %SERVICE% unavailable
    exit /b 0
)

if /i "%TARGET_START%"=="disabled" (
    net stop "%SERVICE%" >nul 2>&1
    sc config "%SERVICE%" start= disabled >nul 2>&1
) else if /i "%TARGET_START%"=="demand" (
    net stop "%SERVICE%" >nul 2>&1
    sc config "%SERVICE%" start= demand >nul 2>&1
) else (
    echo       [!!] Target service tidak valid: %TARGET_START%
    >>"%LOG_FILE%" echo [ERROR] Invalid service target
    exit /b 1
)

if errorlevel 1 (
    echo       [!!] %SERVICE% gagal dikonfigurasi.
    >>"%LOG_FILE%" echo [ERROR] %SERVICE% configuration failed
    exit /b 1
)

if /i "%TARGET_START%"=="disabled" (
    echo       [OK] %SERVICE% dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] %SERVICE% disabled
) else (
    echo       [OK] %SERVICE% diatur Manual / On-Demand.
    >>"%LOG_FILE%" echo [OK] %SERVICE% demand
)

exit /b 0

:: ======================================================================
:: BACKUP SERVICE
:: Format:
:: SERVICE|NAME|START|DELAYED|STATE
:: ======================================================================
:BackupService
set "SERVICE=%~1"
set "S_START="
set "S_DELAYED=0"
set "S_STATE=STOPPED"

reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SERVICE%" /v Start > "%TEMP%\bmj_start_%RANDOM%.tmp" 2>nul
set "START_TMP=%TEMP%\bmj_start_%RANDOM%.tmp"

:: Ambil Start langsung tanpa mengandalkan file sementara yang sama.
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SERVICE%" /v Start 2^>nul ^| findstr /i /r /c:"Start[ ]"') do (
    set "S_START=%%A"
)

for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SERVICE%" /v DelayedAutoStart 2^>nul ^| findstr /i /r /c:"DelayedAutoStart[ ]"') do (
    set "S_DELAYED=%%A"
)

sc query "%SERVICE%" 2>nul | findstr /i "RUNNING" >nul 2>&1
if "%errorlevel%"=="0" set "S_STATE=RUNNING"

if defined S_START (
    >>"%BACKUP_FILE%" echo SERVICE^|%SERVICE%^|%S_START%^|%S_DELAYED%^|%S_STATE%
)

del /f /q "%START_TMP%" >nul 2>&1

exit /b 0

:: ======================================================================
:: BACKUP REGISTRY VALUE
::
:: Format:
:: REG|KEY|VALUE|TYPE|DATA
:: REGABSENT|KEY|VALUE
:: ======================================================================
:BackupRegValue
set "REG_KEY=%~1"
set "REG_VALUE=%~2"
set "REG_TYPE="
set "REG_DATA="
set "REG_FOUND=0"

for /f "skip=2 tokens=1,2,*" %%A in ('reg query "%REG_KEY%" /v "%REG_VALUE%" 2^>nul') do (
    if /i "%%A"=="%REG_VALUE%" (
        set "REG_FOUND=1"
        set "REG_TYPE=%%B"
        set "REG_DATA=%%C"
    )
)

if "%REG_FOUND%"=="1" (
    >>"%BACKUP_FILE%" echo REG^|%REG_KEY%^|%REG_VALUE%^|%REG_TYPE%^|%REG_DATA%
) else (
    >>"%BACKUP_FILE%" echo REGABSENT^|%REG_KEY%^|%REG_VALUE%
)

exit /b 0

:: ======================================================================
:: RESTORE SERVICE
:: ======================================================================
:RestoreService
set "SERVICE=%~1"
set "R_START="
set "R_DELAYED=0"
set "R_STATE=STOPPED"

for /f "tokens=1-5 delims=|" %%A in ('findstr /i /c:"SERVICE^|%SERVICE%^|" "%BACKUP_FILE%"') do (
    set "R_START=%%C"
    set "R_DELAYED=%%D"
    set "R_STATE=%%E"
)

if not defined R_START (
    echo       [--] %SERVICE% tidak memiliki data backup.
    >>"%LOG_FILE%" echo [INFO] %SERVICE% backup data unavailable
    exit /b 0
)

net stop "%SERVICE%" >nul 2>&1

set "RESTORE_OK=1"

if /i "%R_START%"=="0x2" (
    if /i "%R_DELAYED%"=="0x1" (
        sc config "%SERVICE%" start= delayed-auto >nul 2>&1
    ) else (
        sc config "%SERVICE%" start= auto >nul 2>&1
    )
)

if /i "%R_START%"=="0x3" sc config "%SERVICE%" start= demand >nul 2>&1
if /i "%R_START%"=="0x4" sc config "%SERVICE%" start= disabled >nul 2>&1

if /i "%R_START%"=="2" (
    if /i "%R_DELAYED%"=="1" (
        sc config "%SERVICE%" start= delayed-auto >nul 2>&1
    ) else (
        sc config "%SERVICE%" start= auto >nul 2>&1
    )
)

if /i "%R_START%"=="3" sc config "%SERVICE%" start= demand >nul 2>&1
if /i "%R_START%"=="4" sc config "%SERVICE%" start= disabled >nul 2>&1

if errorlevel 1 set "RESTORE_OK=0"

if /i "%R_STATE%"=="RUNNING" (
    net start "%SERVICE%" >nul 2>&1
) else (
    net stop "%SERVICE%" >nul 2>&1
)

if "%RESTORE_OK%"=="1" (
    echo       [OK] %SERVICE% dikembalikan.
    >>"%LOG_FILE%" echo [OK] Restored service %SERVICE%
) else (
    echo       [!!] %SERVICE% gagal dipulihkan sepenuhnya.
    >>"%LOG_FILE%" echo [ERROR] Restore service %SERVICE%
)

exit /b 0

:: ======================================================================
:: RESTORE REGISTRY VALUE
:: ======================================================================
:RestoreRegValue
set "REG_KEY=%~1"
set "REG_VALUE=%~2"
set "R_REG_TYPE="
set "R_REG_DATA="
set "R_REG_FOUND=0"
set "R_REG_ABSENT=0"

:: Cari record REG lengkap
for /f "tokens=1-5 delims=|" %%A in ('findstr /i /c:"REG^|%REG_KEY%^|%REG_VALUE%^|" "%BACKUP_FILE%"') do (
    set "R_REG_TYPE=%%D"
    set "R_REG_DATA=%%E"
    set "R_REG_FOUND=1"
)

:: Cari record REGABSENT
findstr /i /c:"REGABSENT^|%REG_KEY%^|%REG_VALUE%" "%BACKUP_FILE%" >nul 2>&1
if "%errorlevel%"=="0" set "R_REG_ABSENT=1"

if "%R_REG_FOUND%"=="1" (
    reg add "%REG_KEY%" /v "%REG_VALUE%" /t "%R_REG_TYPE%" /d "%R_REG_DATA%" /f >nul 2>&1
    if "%errorlevel%"=="0" (
        echo       [OK] %REG_VALUE% dipulihkan.
        >>"%LOG_FILE%" echo [OK] Restored registry %REG_VALUE%
    ) else (
        echo       [!!] %REG_VALUE% gagal dipulihkan.
        >>"%LOG_FILE%" echo [ERROR] Registry restore %REG_VALUE%
    )
    exit /b 0
)

if "%R_REG_ABSENT%"=="1" (
    reg delete "%REG_KEY%" /v "%REG_VALUE%" /f >nul 2>&1
    if "%errorlevel%"=="0" (
        echo       [OK] %REG_VALUE% dihapus kembali seperti kondisi awal.
        >>"%LOG_FILE%" echo [OK] Removed originally absent registry %REG_VALUE%
    ) else (
        :: Jika memang sudah tidak ada, anggap kondisi sudah sesuai.
        reg query "%REG_KEY%" /v "%REG_VALUE%" >nul 2>&1
        if errorlevel 1 (
            echo       [OK] %REG_VALUE% memang tidak ada seperti kondisi awal.
            >>"%LOG_FILE%" echo [OK] Registry %REG_VALUE% already absent
        ) else (
            echo       [!!] %REG_VALUE% gagal dihapus.
            >>"%LOG_FILE%" echo [ERROR] Registry delete %REG_VALUE%
        )
    )
    exit /b 0
)

echo       [--] Data backup %REG_VALUE% tidak ditemukan.
>>"%LOG_FILE%" echo [INFO] Registry backup unavailable %REG_VALUE%

exit /b 0

:: ======================================================================
:: RESTORE HIBERNATION
:: ======================================================================
:RestoreHibernate
if not exist "%BACKUP_DIR%\hibernate.txt" (
    echo       [!!] Backup Hibernation tidak ditemukan.
    >>"%LOG_FILE%" echo [ERROR] Hibernate backup missing
    exit /b 0
)

set "HIBER_STATE="

for /f "tokens=3" %%A in ('findstr /i "HibernateEnabled" "%BACKUP_DIR%\hibernate.txt"') do (
    set "HIBER_STATE=%%A"
)

if /i "%HIBER_STATE%"=="0x1" (
    powercfg /h on >nul 2>&1
    if "%errorlevel%"=="0" (
        echo       [OK] Hibernation diaktifkan kembali.
        >>"%LOG_FILE%" echo [OK] Hibernate restored ON
    ) else (
        echo       [!!] Hibernation gagal diaktifkan.
        >>"%LOG_FILE%" echo [ERROR] Hibernate restore ON
    )
) else if /i "%HIBER_STATE%"=="0x0" (
    powercfg /h off >nul 2>&1
    if "%errorlevel%"=="0" (
        echo       [OK] Hibernation tetap nonaktif seperti kondisi awal.
        >>"%LOG_FILE%" echo [OK] Hibernate restored OFF
    ) else (
        echo       [!!] Hibernation gagal dikembalikan.
        >>"%LOG_FILE%" echo [ERROR] Hibernate restore OFF
    )
) else (
    echo       [!!] Status Hibernation awal tidak dapat ditentukan.
    echo       [i] Tidak ada perubahan dipaksakan.
    >>"%LOG_FILE%" echo [ERROR] Hibernate original state unknown
)

exit /b 0

:: ======================================================================
:: RESTORE NTFS LAST ACCESS
:: ======================================================================
:RestoreLastAccess
if not exist "%BACKUP_DIR%\lastaccess.txt" (
    echo       [!!] Backup NTFS tidak ditemukan.
    >>"%LOG_FILE%" echo [ERROR] NTFS backup missing
    exit /b 0
)

set "LASTACCESS_VALUE="

:: Cari nilai setelah tanda "=".
for /f "tokens=1,* delims==" %%A in ('findstr /i "DisableLastAccess" "%BACKUP_DIR%\lastaccess.txt"') do (
    set "LASTACCESS_VALUE=%%B"
)

if not defined LASTACCESS_VALUE (
    echo       [!!] Nilai NTFS asli tidak dapat dibaca.
    echo       [i] Tidak ada perubahan dipaksakan.
    >>"%LOG_FILE%" echo [ERROR] Original NTFS value unreadable
    exit /b 0
)

set "LASTACCESS_VALUE=!LASTACCESS_VALUE: =!"
set "LASTACCESS_VALUE=!LASTACCESS_VALUE:	=!"

:: Hanya menerima nilai numerik 0-3.
echo(!LASTACCESS_VALUE!| findstr /r /x "[0-3]" >nul 2>&1
if not "%errorlevel%"=="0" (
    echo       [!!] Nilai NTFS backup tidak valid: %LASTACCESS_VALUE%
    echo       [i] Tidak ada perubahan dipaksakan.
    >>"%LOG_FILE%" echo [ERROR] Invalid NTFS backup value
    exit /b 0
)

fsutil behavior set disablelastaccess %LASTACCESS_VALUE% >nul 2>&1

if "%errorlevel%"=="0" (
    echo       [OK] NTFS Last Access dikembalikan ke nilai awal: %LASTACCESS_VALUE%.
    >>"%LOG_FILE%" echo [OK] NTFS restored: %LASTACCESS_VALUE%
) else (
    echo       [!!] NTFS Last Access gagal dipulihkan.
    >>"%LOG_FILE%" echo [ERROR] NTFS restore failed
)

exit /b 0

:: ======================================================================
:: RESTORE POWER PLAN
:: ======================================================================
:RestorePowerPlan
if not exist "%BACKUP_DIR%\powerplan.txt" (
    echo       [!!] Backup Power Plan tidak ditemukan.
    echo       [i] Tidak ada perubahan dipaksakan.
    >>"%LOG_FILE%" echo [ERROR] Power plan backup missing
    exit /b 0
)

set "OLD_PLAN="

for /f "tokens=4" %%A in ('findstr /i "Power Scheme GUID" "%BACKUP_DIR%\powerplan.txt"') do (
    if not defined OLD_PLAN set "OLD_PLAN=%%A"
)

if not defined OLD_PLAN (
    echo       [!!] Power Plan lama tidak dapat dibaca.
    echo       [i] Tidak dipaksa ke Balanced.
    >>"%LOG_FILE%" echo [ERROR] Original power plan unreadable
    exit /b 0
)

powercfg /setactive %OLD_PLAN% >nul 2>&1

if "%errorlevel%"=="0" (
    echo       [OK] Power Plan sebelumnya dipulihkan.
    >>"%LOG_FILE%" echo [OK] Power plan restored: %OLD_PLAN%
) else (
    echo       [!!] Power Plan lama gagal dipulihkan.
    echo       [i] Tidak mengganti dengan plan lain secara otomatis.
    >>"%LOG_FILE%" echo [ERROR] Power plan restore failed
)

exit /b 0

:: ======================================================================
:: CLEANUP TEMP KONSERVATIF
::
:: Argumen:
::   %1 = folder
::   %2 = umur file minimum dalam hari
::
:: Menghindari penghapusan file TEMP yang baru dibuat.
:: ======================================================================
:CleanOldTemp
set "CLEAN_DIR=%~1"
set "CLEAN_DAYS=%~2"

if not exist "%CLEAN_DIR%\" (
    echo       [i] Folder TEMP tidak ditemukan.
    >>"%LOG_FILE%" echo [INFO] Temp folder missing: %CLEAN_DIR%
    exit /b 0
)

:: Hapus file lebih tua dari X hari.
forfiles /p "%CLEAN_DIR%" /s /m *.* /d -%CLEAN_DAYS% /c "cmd /c del /f /q @path" >nul 2>&1

:: Hapus folder kosong yang tersisa secara hati-hati.
for /f "delims=" %%D in ('dir "%CLEAN_DIR%" /ad /b /s 2^>nul') do (
    rd "%%D" >nul 2>&1
)

echo       [OK] TEMP lama dibersihkan secara konservatif.
>>"%LOG_FILE%" echo [OK] Conservative TEMP cleanup: %CLEAN_DIR%

exit /b 0

:: ======================================================================
:: SHOW SERVICE
:: ======================================================================
:ShowService
set "SERVICE=%~1"

echo.
echo       [%SERVICE%]

sc query "%SERVICE%" >nul 2>&1
if errorlevel 1 (
    echo       Status       : Tidak tersedia
    echo       Start Type   : Tidak tersedia
    exit /b 0
)

sc query "%SERVICE%" | findstr /i "STATE"
sc qc "%SERVICE%" | findstr /i "START_TYPE"

exit /b 0

:: ======================================================================
:: EXIT
:: ======================================================================
:exit
cls
echo.
echo  ==============================================================================
echo.
echo                 SYSTEM OPTIMIZER WINDOWS 10 HDD
echo                            BM JAYA 2 v%CURRENT_VER%
echo.
echo                    Terima kasih telah menggunakan
echo                       System Optimizer HDD.
echo.
echo  ==============================================================================
echo.

>>"%LOG_FILE%" echo EXIT - %date% %time%

if "%LOCK_CREATED%"=="1" (
    del /f /q "%LOCK_FILE%" >nul 2>&1
)

endlocal
exit /b 0
```
