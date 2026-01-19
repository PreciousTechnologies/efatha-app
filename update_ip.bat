@echo off
REM ========================================================================
REM Auto IP Update Script for Efatha App
REM This script automatically detects your IP and updates the Flutter config
REM ========================================================================

echo.
echo ========================================================================
echo              EFATHA APP - AUTO IP UPDATE TOOL
echo ========================================================================
echo.

REM Get the current IP address (IPv4)
echo [1/4] Detecting your current IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found
)

:found
REM Trim leading spaces
set IP=%IP: =%

echo.
echo [✓] Current IP Address: %IP%
echo.

REM Check if IP was found
if "%IP%"=="" (
    echo [✗] ERROR: Could not detect IP address!
    echo     Please check your network connection.
    pause
    exit /b 1
)

REM Path to the Flutter config file
set CONFIG_FILE=lib\core\config\api_config.dart

echo [2/4] Checking if config file exists...
if not exist "%CONFIG_FILE%" (
    echo [✗] ERROR: Config file not found!
    echo     Expected location: %CONFIG_FILE%
    pause
    exit /b 1
)

echo [✓] Config file found: %CONFIG_FILE%
echo.

REM Create backup of current config
echo [3/4] Creating backup of current configuration...
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul 2>&1
echo [✓] Backup created: %CONFIG_FILE%.backup
echo.

REM Update the IP in the config file
echo [4/4] Updating IP address in configuration...

REM Create a temporary PowerShell script to do the replacement
echo $content = Get-Content '%CONFIG_FILE%' -Raw > temp_update.ps1
echo $content = $content -replace "http://[\d\.]+:8000", "http://%IP%:8000" >> temp_update.ps1
echo Set-Content '%CONFIG_FILE%' -Value $content >> temp_update.ps1

REM Execute the PowerShell script
powershell -ExecutionPolicy Bypass -File temp_update.ps1

REM Clean up temporary file
del temp_update.ps1 >nul 2>&1

echo [✓] Configuration updated successfully!
echo.

REM Show the updated configuration
echo ========================================================================
echo                    UPDATED CONFIGURATION
echo ========================================================================
echo.
echo New API Base URL: http://%IP%:8000
echo.
echo Configuration file: %CONFIG_FILE%
echo.

REM Ask if user wants to start the Django server
echo ========================================================================
set /p START_SERVER="Do you want to start the Django server now? (Y/N): "
echo.

if /i "%START_SERVER%"=="Y" (
    echo Starting Django server at http://%IP%:8000...
    echo.
    echo ========================================================================
    echo Press Ctrl+C to stop the server when done
    echo ========================================================================
    echo.
    cd backend
    python manage.py runserver 0.0.0.0:8000
) else (
    echo.
    echo To start the Django server manually, run:
    echo   cd backend
    echo   python manage.py runserver 0.0.0.0:8000
    echo.
)

echo ========================================================================
echo                         UPDATE COMPLETE
echo ========================================================================
echo.
pause
