```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v1.2
mode con: cols=78 lines=36
color 0b

:: ======================================================================
:: SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2
:: VERSION 1.2 - POS SAFE
:: ======================================================================
set "CURRENT_VER=1.2"
set "APP_NAME=System Optimizer Windows 10 HDD"
set "VER_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/KURZIBNANAM/optimizer-hdd/main/optimizer.bat"
set "BACKUP_DIR=%ProgramData%\BMJAYA2\SystemOptimizer\Backup"
set "LOG_DIR=%ProgramData%\BMJAYA2\SystemOptimizer\Logs"
set "BACKUP_FILE=%BACKUP_DIR%\system_backup.dat"
set "LOG_FILE=%LOG_DIR%\optimizer.log"

:: ======================================================================
:: CEK ADMINISTRATOR
:: ======================================================================
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    cls
    echo.
    echo  ============================================================================
    echo       SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 v%CURRENT_VER%
    echo  ============================================================================
    echo.
    echo       [!!] HAK ADMINISTRATOR DIBUTUHKAN
    echo.
    echo       Klik kanan file BAT ini lalu pilih:
    echo.
    echo                         RUN AS ADMINISTRATOR
    echo.
    echo  ============================================================================
    pause
    exit /b 1
)

:: ======================================================================
:: INISIALISASI
:: ======================================================================
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

:: ======================================================================
:: INFORMASI WINDOWS
:: ======================================================================
set "WIN_NAME=UNKNOWN"
ver | findstr /i "10.0" >nul 2>&1
if "%errorlevel%"=="0" set "WIN_NAME=Windows 10"

:: ======================================================================
:: AUTO UPDATE
:: ======================================================================
:UPDATE_CHECK
cls
echo.
echo  ============================================================================
echo                    SYSTEM OPTIMIZER WINDOWS 10 HDD
echo                              BM JAYA 2
echo  ============================================================================
echo.
echo       Versi terpasang : v%CURRENT_VER%
echo       [*] Memeriksa pembaruan...
echo.

where curl >nul 2>&1
if not "%errorlevel%"=="0" (
    echo       [!] CURL tidak tersedia.
    echo       [i] Melanjutkan dengan versi saat ini...
    timeout /t 2 /nobreak >nul
    goto menu
)

set "REMOTE_VER="
for /f "usebackq tokens=1 delims= " %%A in (`curl -L -s --connect-timeout 3 -m 5 "%VER_URL%" 2^>nul`) do (
    if not defined REMOTE_VER set "REMOTE_VER=%%A"
)

if not defined REMOTE_VER (
    echo       [i] Server update tidak dapat dihubungi.
    echo       [i] Melanjutkan dengan versi saat ini...
    timeout /t 2 /nobreak >nul
    goto menu
)

set "REMOTE_VER=!REMOTE_VER:v=!"
set "REMOTE_VER=!REMOTE_VER: =!"

echo       Versi repository : v%REMOTE_VER%
echo.

if /i "%REMOTE_VER%"=="%CURRENT_VER%" (
    echo       [OK] Anda sudah menggunakan versi terbaru.
    timeout /t 2 /nobreak >nul
    goto menu
)

echo       [!] Versi baru terdeteksi: v%REMOTE_VER%
echo       [*] Mengunduh pembaruan...
echo.

set "UPDATE_TEMP=%TEMP%\BMJAYA2_optimizer_%RANDOM%.bat"
curl -L -s --connect-timeout 5 -m 30 -o "%UPDATE_TEMP%" "%UPDATE_URL%" >nul 2>&1

if not exist "%UPDATE_TEMP%" (
    echo       [!!] Gagal mengunduh pembaruan.
    echo       [i] Melanjutkan versi saat ini...
    timeout /t 2 /nobreak >nul
    goto menu
)

:: Validasi sederhana agar file hasil download benar-benar BAT
findstr /i /c:"CURRENT_VER=" "%UPDATE_TEMP%" >nul 2>&1
if not "%errorlevel%"=="0" (
    echo       [!!] File update tidak valid.
    del /f /q "%UPDATE_TEMP%" >nul 2>&1
    timeout /t 2 /nobreak >nul
    goto menu
)

echo       [OK] File update berhasil diunduh.
echo       [*] Menyiapkan proses penggantian file...
echo.

set "SELF_UPDATER=%TEMP%\BMJAYA2_self_updater_%RANDOM%.bat"
(
    echo @echo off
    echo timeout /t 2 /nobreak ^>nul
    echo copy /y "%UPDATE_TEMP%" "%~f0" ^>nul 2^>^&1
    echo if exist "%UPDATE_TEMP%" del /f /q "%UPDATE_TEMP%" ^>nul 2^>^&1
    echo start "" "%~f0"
    echo del /f /q "%%~f0" ^>nul 2^>^&1
) > "%SELF_UPDATER%"

start "" /min "%SELF_UPDATER%"
exit /b

:: ======================================================================
:: MENU UTAMA
:: ======================================================================
:menu
cls
echo.
echo  ============================================================================
echo       SYSTEM OPTIMIZER WINDOWS 10 HDD - BM JAYA 2 - v%CURRENT_VER%
echo  ============================================================================
echo       Pengembang : Khairullah Irfansyah, S.Kom
echo       Unit       : BM JAYA 2
echo  ============================================================================
echo.
echo       SISTEM:
echo.
echo       Windows    : %WIN_NAME%
echo       Komputer   : %COMPUTERNAME%
echo       Backup     : %BACKUP_DIR%
echo.
echo  ----------------------------------------------------------------------------
echo       PILIHAN MENU:
echo.
echo       [1] Jalankan Optimasi HDD - POS Safe Mode
echo       [2] Kembalikan Pengaturan Sebelum Optimasi
echo       [3] Pemeriksaan Sistem
echo       [4] Keluar
echo.
echo  ============================================================================
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
echo  ============================================================================
echo                  OPTIMASI WINDOWS 10 HDD - POS SAFE MODE
echo  ============================================================================
echo.
echo       Target:
echo       - Windows 10
echo       - HDD mekanik
echo       - Komputer kasir / POS
echo       - Mengurangi aktivitas disk background
echo       - Menjaga database, printer dan jaringan
echo.
echo  ============================================================================

:: ----------------------------------------------------------------------
:: DETEKSI MEDIA
:: ----------------------------------------------------------------------
echo.
echo  [*] Mendeteksi media penyimpanan...
set "HDD_FOUND=0"
set "SSD_FOUND=0"
set "DISK_INFO="

for /f "skip=1 tokens=*" %%A in ('wmic diskdrive get Model^,MediaType 2^>nul') do (
    if not defined DISK_INFO if not "%%A"=="" set "DISK_INFO=%%A"
)

wmic diskdrive get MediaType 2>nul | findstr /i "Fixed hard disk" >nul 2>&1
if "%errorlevel%"=="0" set "HDD_FOUND=1"

wmic diskdrive get Model 2>nul | findstr /i "SSD NVMe" >nul 2>&1
if "%errorlevel%"=="0" set "SSD_FOUND=1"

if "%SSD_FOUND%"=="1" (
    echo       [!] SSD/NVMe terdeteksi pada sistem.
    echo       [i] Optimizer tetap berjalan dalam mode POS Safe.
) else if "%HDD_FOUND%"=="1" (
    echo       [OK] HDD terdeteksi.
) else (
    echo       [i] Tipe media tidak dapat dipastikan secara otomatis.
    echo       [i] Mode POS Safe tetap digunakan.
)

:: ----------------------------------------------------------------------
:: CEK RUANG DISK
:: ----------------------------------------------------------------------
echo.
echo  [*] Memeriksa ruang drive sistem...
for /f "tokens=3" %%A in ('dir "%SystemDrive%\" ^| findstr /i "bytes free"') do set "FREE_SPACE=%%A"
echo       Drive sistem : %SystemDrive%
if defined FREE_SPACE echo       Ruang kosong : %FREE_SPACE%

:: ----------------------------------------------------------------------
:: BACKUP
:: ----------------------------------------------------------------------
echo.
echo  [*] Memeriksa backup konfigurasi...

if exist "%BACKUP_FILE%" (
    echo.
    echo       [!] Backup konfigurasi sebelumnya ditemukan.
    echo.
    choice /C YN /N /M "       Gunakan backup lama? [Y/N] : "
    if errorlevel 2 goto create_backup
    echo       [OK] Backup lama dipertahankan.
    goto backup_done
)

:create_backup
echo.
echo  [*] Membuat backup konfigurasi ASLI sebelum optimasi...
echo.

> "%BACKUP_FILE%" echo # SYSTEM OPTIMIZER WINDOWS 10 HDD v%CURRENT_VER%
>>"%BACKUP_FILE%" echo # Backup dibuat: %date% %time%
>>"%BACKUP_FILE%" echo # Format service: SERVICE^|NAME^|START^|DELAYED^|STATE
>>"%BACKUP_FILE%" echo.

call :BackupService WSearch
call :BackupService SysMain
call :BackupService DiagTrack
call :BackupService DoSvc
call :BackupService dmwappushservice
call :BackupService BITS

:: Backup registry yang memang diubah
reg export "HKCU\Control Panel\Desktop" "%BACKUP_DIR%\desktop.reg" /y >nul 2>&1
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "%BACKUP_DIR%\visualeffects.reg" /y >nul 2>&1
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "%BACKUP_DIR%\backgroundapps.reg" /y >nul 2>&1

:: Backup Power Plan
powercfg /getactivescheme > "%BACKUP_DIR%\powerplan.txt" 2>&1

:: Backup Hibernation
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled > "%BACKUP_DIR%\hibernate.txt" 2>&1

:: Backup NTFS behavior
fsutil behavior query disablelastaccess > "%BACKUP_DIR%\lastaccess.txt" 2>&1

echo       [OK] Backup konfigurasi berhasil dibuat.

:backup_done
>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo ============================================================
>>"%LOG_FILE%" echo OPTIMIZATION STARTED - %date% %time%
>>"%LOG_FILE%" echo COMPUTER: %COMPUTERNAME%
>>"%LOG_FILE%" echo VERSION: %CURRENT_VER%

echo.
echo  ============================================================================
echo                              MULAI OPTIMASI
echo  ============================================================================

:: ======================================================================
:: SERVICE
:: ======================================================================
echo.
echo  [BAGIAN 1] SERVICE BACKGROUND
echo  ----------------------------------------------------------------------------

echo  [1/6] Windows Search...
net stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Windows Search dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] WSearch disabled
) else (
    echo       [!!] Windows Search gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] WSearch
)

echo  [2/6] SysMain...
net stop "SysMain" >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] SysMain dinonaktifkan untuk mengurangi aktivitas HDD.
    >>"%LOG_FILE%" echo [OK] SysMain disabled
) else (
    echo       [!!] SysMain gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] SysMain
)

echo  [3/6] DiagTrack...
net stop "DiagTrack" >nul 2>&1
sc config "DiagTrack" start= disabled >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] DiagTrack dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] DiagTrack disabled
) else (
    echo       [i] DiagTrack tidak tersedia / tidak dapat diubah.
    >>"%LOG_FILE%" echo [INFO] DiagTrack unavailable
)

echo  [4/6] Delivery Optimization...
net stop "DoSvc" >nul 2>&1
sc config "DoSvc" start= demand >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Delivery Optimization diatur Manual.
    >>"%LOG_FILE%" echo [OK] DoSvc manual
) else (
    echo       [!!] Delivery Optimization gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] DoSvc
)

echo  [5/6] WAP Push Service...
sc config "dmwappushservice" start= demand >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] WAP Push Service diatur Manual.
    >>"%LOG_FILE%" echo [OK] dmwappushservice manual
) else (
    echo       [i] WAP Push Service tidak tersedia.
    >>"%LOG_FILE%" echo [INFO] dmwappushservice unavailable
)

echo  [6/6] Background Intelligent Transfer Service...
sc config "BITS" start= demand >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] BITS diatur Manual / On-Demand.
    >>"%LOG_FILE%" echo [OK] BITS manual
) else (
    echo       [!!] BITS gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] BITS
)

:: ======================================================================
:: SYSTEM & UI
:: ======================================================================
echo.
echo  [BAGIAN 2] SYSTEM & UI
echo  ----------------------------------------------------------------------------

echo  [1/7] Hibernation...
powercfg /h off >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Hibernation dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] Hibernation off
) else (
    echo       [!!] Hibernation gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] Hibernation
)

echo  [2/7] Visual Effects...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
echo       [OK] Visual Effects dioptimalkan.
>>"%LOG_FILE%" echo [OK] Visual Effects

echo  [3/7] MenuShowDelay...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] MenuShowDelay = 0 ms.
    >>"%LOG_FILE%" echo [OK] MenuShowDelay
) else (
    echo       [!!] MenuShowDelay gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] MenuShowDelay
)

echo  [4/7] AutoEndTasks...
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 0 /f >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] AutoEndTasks tetap aman.
    >>"%LOG_FILE%" echo [OK] AutoEndTasks
) else (
    echo       [!!] AutoEndTasks gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] AutoEndTasks
)

echo  [5/7] Shutdown Timeout...
echo       [OK] WaitToKillAppTimeout tidak diubah.
echo       [OK] WaitToKillServiceTimeout tidak diubah.
echo       [OK] Database/POS diberikan shutdown normal.
>>"%LOG_FILE%" echo [OK] Shutdown timeout untouched

echo  [6/7] NTFS Last Access...
fsutil behavior set disablelastaccess 1 >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] NTFS Last Access Update dinonaktifkan.
    >>"%LOG_FILE%" echo [OK] NTFS last access disabled
) else (
    echo       [!!] NTFS Last Access gagal diubah.
    >>"%LOG_FILE%" echo [ERROR] NTFS last access
)

echo  [7/7] Background Apps...
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
echo  [BAGIAN 3] CLEANUP
echo  ----------------------------------------------------------------------------

echo  [1/4] User TEMP...
del /f /q "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo       [OK] TEMP user dibersihkan.
>>"%LOG_FILE%" echo [OK] User TEMP cleanup

echo  [2/4] Windows TEMP...
del /f /q "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo       [OK] Windows TEMP dibersihkan.
>>"%LOG_FILE%" echo [OK] Windows TEMP cleanup

echo  [3/4] DNS Cache...
ipconfig /flushdns >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] DNS Cache berhasil di-flush.
    >>"%LOG_FILE%" echo [OK] DNS flush
) else (
    echo       [!!] DNS Cache gagal di-flush.
    >>"%LOG_FILE%" echo [ERROR] DNS flush
)

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
    echo       [!!] High Performance tidak tersedia.
    >>"%LOG_FILE%" echo [ERROR] High Performance
)

:: ======================================================================
:: DISK MAINTENANCE
:: ======================================================================
echo.
echo  [BAGIAN 5] DISK MAINTENANCE
echo  ----------------------------------------------------------------------------

echo  [1/3] Status disk...
wmic diskdrive get Model,Status 2>nul
echo.

echo  [2/3] File system...
fsutil dirty query %SystemDrive% >nul 2>&1
if "%errorlevel%"=="0" (
    echo       [OK] Pemeriksaan file system dapat dilakukan.
) else (
    echo       [!!] Status file system tidak dapat dibaca.
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
echo  ============================================================================
echo                            OPTIMASI BERHASIL
echo  ============================================================================
echo.
echo       SYSTEM OPTIMIZER WINDOWS 10 HDD v%CURRENT_VER%
echo.
echo       [OK] Windows Search         : Disabled
echo       [OK] SysMain                : Disabled
echo       [OK] Telemetry              : Reduced
echo       [OK] Delivery Optimization  : Manual
echo       [OK] Background Apps        : Reduced
echo       [OK] Visual Effects         : Optimized
echo       [OK] NTFS                   : Optimized
echo       [OK] DNS Cache              : Flushed
echo       [OK] TEMP                   : Cleaned
echo       [OK] Power Plan             : High Performance
echo.
echo  ----------------------------------------------------------------------------
echo       DATABASE / POS SAFETY
echo.
echo       [OK] Shutdown timeout tidak dipangkas.
echo       [OK] Tidak ada kill paksa database.
echo       [OK] Printer tidak disentuh.
echo       [OK] Network service penting tidak dimatikan.
echo       [OK] Backup konfigurasi telah dibuat.
echo  ----------------------------------------------------------------------------
echo.
echo       Log:
echo       %LOG_FILE%
echo.
echo       [!] Restart Windows disarankan.
echo  ============================================================================
echo.
pause
goto menu

:: ======================================================================
:: RESTORE
:: ======================================================================
:restore
cls
echo.
echo  ============================================================================
echo                    RESTORE KONFIGURASI SEBELUM OPTIMASI
echo  ============================================================================
echo.

if not exist "%BACKUP_FILE%" (
    echo       [!!] Backup konfigurasi tidak ditemukan.
    echo.
    echo       Restore dibatalkan demi keamanan.
    echo.
    echo       Lokasi:
    echo       %BACKUP_FILE%
    echo.
    pause
    goto menu
)

echo       Backup ditemukan:
echo       %BACKUP_FILE%
echo.
echo       Restore akan mengembalikan konfigurasi berdasarkan
echo       kondisi yang disimpan SEBELUM optimasi.
echo.
choice /C YN /N /M "  Lanjutkan Restore? [Y/N] : "
if errorlevel 2 goto menu

echo.
echo  ============================================================================
echo                              MULAI RESTORE
echo  ============================================================================

echo.
echo  [BAGIAN 1] RESTORE SERVICE
echo  ----------------------------------------------------------------------------
call :RestoreService WSearch
call :RestoreService SysMain
call :RestoreService DiagTrack
call :RestoreService DoSvc
call :RestoreService dmwappushservice
call :RestoreService BITS

echo.
echo  [BAGIAN 2] RESTORE REGISTRY
echo  ----------------------------------------------------------------------------

if exist "%BACKUP_DIR%\desktop.reg" (
    reg import "%BACKUP_DIR%\desktop.reg" >nul 2>&1
    if "%errorlevel%"=="0" (echo       [OK] Desktop registry dipulihkan.) else (echo       [!!] Desktop registry gagal dipulihkan.)
) else echo       [!!] Desktop backup tidak ditemukan.

if exist "%BACKUP_DIR%\visualeffects.reg" (
    reg import "%BACKUP_DIR%\visualeffects.reg" >nul 2>&1
    if "%errorlevel%"=="0" (echo       [OK] Visual Effects dipulihkan.) else (echo       [!!] Visual Effects gagal dipulihkan.)
) else echo       [!!] Visual Effects backup tidak ditemukan.

if exist "%BACKUP_DIR%\backgroundapps.reg" (
    reg import "%BACKUP_DIR%\backgroundapps.reg" >nul 2>&1
    if "%errorlevel%"=="0" (echo       [OK] Background Apps dipulihkan.) else (echo       [!!] Background Apps gagal dipulihkan.)
) else echo       [!!] Background Apps backup tidak ditemukan.

echo.
echo  [BAGIAN 3] RESTORE HIBERNATION
echo  ----------------------------------------------------------------------------
call :RestoreHibernate

echo.
echo  [BAGIAN 4] RESTORE NTFS
echo  ----------------------------------------------------------------------------
call :RestoreLastAccess

echo.
echo  [BAGIAN 5] RESTORE POWER PLAN
echo  ----------------------------------------------------------------------------
call :RestorePowerPlan

>>"%LOG_FILE%" echo RESTORE FINISHED - %date% %time%

echo.
echo  ============================================================================
echo                              RESTORE SELESAI
echo  ============================================================================
echo.
echo       Konfigurasi dikembalikan berdasarkan backup sebelum optimasi.
echo.
echo       [OK] Service
echo       [OK] Registry
echo       [OK] Hibernation
echo       [OK] NTFS
echo       [OK] Power Plan
echo.
echo       [!] Restart Windows disarankan agar seluruh perubahan diterapkan.
echo  ============================================================================
echo.
pause
goto menu

:: ======================================================================
:: DIAGNOSTICS
:: ======================================================================
:diagnostics
cls
echo.
echo  ============================================================================
echo                             SYSTEM DIAGNOSTICS
echo  ============================================================================
echo.
echo  [1] INFORMASI WINDOWS
echo  ----------------------------------------------------------------------------
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"
echo.
echo  [2] CPU
echo  ----------------------------------------------------------------------------
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors /format:list 2>nul
echo.
echo  [3] RAM
echo  ----------------------------------------------------------------------------
wmic computersystem get TotalPhysicalMemory /format:list 2>nul
echo.
echo  [4] DISK
echo  ----------------------------------------------------------------------------
wmic diskdrive get Model,InterfaceType,MediaType,Size,Status 2>nul
echo.
echo  [5] DRIVE SISTEM
echo  ----------------------------------------------------------------------------
wmic logicaldisk where "DeviceID='%SystemDrive%'" get DeviceID,FreeSpace,Size 2>nul
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
if exist "%BACKUP_FILE%" (
    echo       [OK] Backup tersedia.
    echo       %BACKUP_FILE%
) else (
    echo       [--] Backup belum dibuat.
)
echo.
echo  ============================================================================
pause
goto menu

:: ======================================================================
:: BACKUP SERVICE
:: Format: SERVICE|NAME|START|DELAYED|STATE
:: ======================================================================
:BackupService
set "SERVICE=%~1"
set "S_START="
set "S_DELAYED=0"
set "S_STATE=STOPPED"

reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SERVICE%" /v Start > "%TEMP%\bmj_start.tmp" 2>nul
for /f "tokens=3" %%A in ('findstr /i "Start" "%TEMP%\bmj_start.tmp"') do set "S_START=%%A"
del /f /q "%TEMP%\bmj_start.tmp" >nul 2>&1

reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SERVICE%" /v DelayedAutoStart > "%TEMP%\bmj_delay.tmp" 2>nul
for /f "tokens=3" %%A in ('findstr /i "DelayedAutoStart" "%TEMP%\bmj_delay.tmp"') do set "S_DELAYED=%%A"
del /f /q "%TEMP%\bmj_delay.tmp" >nul 2>&1

sc query "%SERVICE%" > "%TEMP%\bmj_state.tmp" 2>nul
findstr /i "RUNNING" "%TEMP%\bmj_state.tmp" >nul 2>&1
if "%errorlevel%"=="0" set "S_STATE=RUNNING"
del /f /q "%TEMP%\bmj_state.tmp" >nul 2>&1

if defined S_START (
    >>"%BACKUP_FILE%" echo SERVICE^|%SERVICE%^|%S_START%^|%S_DELAYED%^|%S_STATE%
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
    exit /b 0
)

net stop "%SERVICE%" >nul 2>&1

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

if /i "%R_STATE%"=="RUNNING" (
    net start "%SERVICE%" >nul 2>&1
) else (
    net stop "%SERVICE%" >nul 2>&1
)

echo       [OK] %SERVICE% dikembalikan.
>>"%LOG_FILE%" echo [OK] Restored service %SERVICE%

exit /b 0

:: ======================================================================
:: RESTORE HIBERNATION
:: ======================================================================
:RestoreHibernate
if not exist "%BACKUP_DIR%\hibernate.txt" (
    echo       [!!] Backup Hibernation tidak ditemukan.
    exit /b 0
)

set "HIBER_STATE="
for /f "tokens=3" %%A in ('findstr /i "HibernateEnabled" "%BACKUP_DIR%\hibernate.txt"') do set "HIBER_STATE=%%A"

if /i "%HIBER_STATE%"=="0x1" (
    powercfg /h on >nul 2>&1
    echo       [OK] Hibernation diaktifkan kembali.
) else if /i "%HIBER_STATE%"=="0x0" (
    powercfg /h off >nul 2>&1
    echo       [OK] Hibernation tetap nonaktif seperti kondisi awal.
) else (
    echo       [!!] Status Hibernation awal tidak dapat ditentukan.
)

exit /b 0

:: ======================================================================
:: RESTORE NTFS LAST ACCESS
:: ======================================================================
:RestoreLastAccess
if not exist "%BACKUP_DIR%\lastaccess.txt" (
    echo       [!!] Backup NTFS tidak ditemukan.
    exit /b 0
)

set "LASTACCESS_VALUE="
for /f "tokens=1,* delims==" %%A in ('findstr /i "DisableLastAccess" "%BACKUP_DIR%\lastaccess.txt"') do set "LASTACCESS_VALUE=%%B"

if defined LASTACCESS_VALUE (
    echo %LASTACCESS_VALUE% | findstr /r /i "0x1 1" >nul 2>&1
    if "%errorlevel%"=="0" (
        fsutil behavior set disablelastaccess 1 >nul 2>&1
        echo       [OK] NTFS Last Access dikembalikan ke kondisi awal.
        exit /b 0
    )
)

:: Jika nilai awal tidak terbaca dengan format yang dapat dipastikan,
:: gunakan Windows default agar tidak meninggalkan kondisi optimasi.
fsutil behavior set disablelastaccess 0 >nul 2>&1
echo       [OK] NTFS Last Access dikembalikan ke konfigurasi Windows.
exit /b 0

:: ======================================================================
:: RESTORE POWER PLAN
:: ======================================================================
:RestorePowerPlan
if not exist "%BACKUP_DIR%\powerplan.txt" (
    powercfg /setactive SCHEME_BALANCED >nul 2>&1
    echo       [i] Backup Power Plan tidak ditemukan. Balanced digunakan.
    exit /b 0
)

set "OLD_PLAN="
for /f "tokens=4" %%A in ('findstr /i "Power Scheme GUID" "%BACKUP_DIR%\powerplan.txt"') do set "OLD_PLAN=%%A"

if defined OLD_PLAN (
    powercfg /setactive %OLD_PLAN% >nul 2>&1
    if "%errorlevel%"=="0" (
        echo       [OK] Power Plan sebelumnya dipulihkan.
    ) else (
        powercfg /setactive SCHEME_BALANCED >nul 2>&1
        echo       [i] Power Plan lama gagal dipulihkan. Balanced digunakan.
    )
) else (
    powercfg /setactive SCHEME_BALANCED >nul 2>&1
    echo       [i] Power Plan lama tidak dapat dibaca. Balanced digunakan.
)

exit /b 0

:: ======================================================================
:: SHOW SERVICE
:: ======================================================================
:ShowService
set "SERVICE=%~1"
echo.
echo       [%SERVICE%]
sc query "%SERVICE%" | findstr /i "STATE"
sc qc "%SERVICE%" | findstr /i "START_TYPE"
exit /b 0

:: ======================================================================
:: EXIT
:: ======================================================================
:exit
cls
echo.
echo  ============================================================================
echo.
echo                 SYSTEM OPTIMIZER WINDOWS 10 HDD
echo                            BM JAYA 2 v%CURRENT_VER%
echo.
echo                    Terima kasih telah menggunakan
echo                       System Optimizer HDD.
echo.
echo  ============================================================================
echo.
endlocal
exit /b 0
```
