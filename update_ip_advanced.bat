@echo off
REM ========================================================================
REM Advanced IP Update Script with Network Detection
REM ========================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================================================
echo          EFATHA APP - ADVANCED IP UPDATE TOOL
echo ========================================================================
echo.

REM Show current configuration
echo [INFO] Checking current configuration...
echo.

set CONFIG_FILE=lib\core\config\api_config.dart

if exist "%CONFIG_FILE%" (
    for /f "tokens=*" %%a in ('findstr /C:"baseUrl" "%CONFIG_FILE%"') do (
        echo Current Config: %%a
    )
) else (
    echo [✗] Config file not found!
    pause
    exit /b 1
)

echo.
echo ========================================================================
echo              DETECTING AVAILABLE NETWORK INTERFACES
echo ========================================================================
echo.

REM Detect all IPv4 addresses
set count=0
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set /a count+=1
    set IP!count!=%%a
    set IP!count!=!IP%count%: =!
    echo [!count!] !IP%count%!
)

if %count%==0 (
    echo [✗] No IP addresses found!
    echo     Please check your network connection.
    pause
    exit /b 1
)

echo.

if %count%==1 (
    set SELECTED_IP=!IP1!
    echo [AUTO] Only one IP found, using: !SELECTED_IP!
) else (
    echo Multiple IP addresses detected.
    echo.
    set /p CHOICE="Select IP address number (1-%count%): "
    
    if not defined IP!CHOICE! (
        echo [✗] Invalid selection!
        pause
        exit /b 1
    )
    
    set SELECTED_IP=!IP%CHOICE%!
)

echo.
echo ========================================================================
echo [✓] Selected IP: %SELECTED_IP%
echo ========================================================================
echo.

REM Create backup
echo [BACKUP] Creating backup...
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%" >nul 2>&1
echo [✓] Backup created
echo.

REM Update configuration
echo [UPDATE] Updating configuration file...

powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'http://[\d.]+:8000', 'http://%SELECTED_IP%:8000' | Set-Content '%CONFIG_FILE%'"

echo [✓] Configuration updated!
echo.

REM Verify update
echo ========================================================================
echo                    VERIFICATION
echo ========================================================================
echo.

for /f "tokens=*" %%a in ('findstr /C:"baseUrl" "%CONFIG_FILE%"') do (
    echo New Config: %%a
)

echo.
echo ========================================================================
echo                      NEXT STEPS
echo ========================================================================
echo.
echo 1. Start Django server:
echo    cd backend
echo    python manage.py runserver 0.0.0.0:8000
echo.
echo 2. Run Flutter app:
echo    flutter run
echo.
echo 3. Access from other devices using: http://%SELECTED_IP%:8000
echo.
echo ========================================================================

set /p START="Start Django server now? (Y/N): "

if /i "%START%"=="Y" (
    echo.
    echo Starting server at http://%SELECTED_IP%:8000...
    echo.
    cd backend
    python manage.py runserver 0.0.0.0:8000
)

endlocal
