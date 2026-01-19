@echo off
REM ========================================================================
REM EFATHA APP - ONE-CLICK STARTUP SCRIPT
REM This script automatically:
REM   1. Detects your current IP
REM   2. Updates Flutter configuration
REM   3. Starts Django backend server
REM   4. Optionally runs Flutter app
REM ========================================================================

setlocal enabledelayedexpansion

color 0A
title Efatha App - Quick Start

echo.
echo  ███████╗███████╗ █████╗ ████████╗██╗  ██╗ █████╗ 
echo  ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║  ██║██╔══██╗
echo  █████╗  █████╗  ███████║   ██║   ███████║███████║
echo  ██╔══╝  ██╔══╝  ██╔══██║   ██║   ██╔══██║██╔══██║
echo  ███████╗██║     ██║  ██║   ██║   ██║  ██║██║  ██║
echo  ╚══════╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
echo.
echo              ONE-CLICK STARTUP SCRIPT
echo ========================================================================
echo.

REM Step 1: Detect IP
echo [1/5] Detecting IP address...

set count=0
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set /a count+=1
    set tempIP=%%a
    set tempIP=!tempIP: =!
    
    REM Skip localhost
    if not "!tempIP!"=="127.0.0.1" (
        set IP=!tempIP!
    )
)

if not defined IP (
    echo [✗] ERROR: Could not detect IP address!
    pause
    exit /b 1
)

echo [✓] IP Address: %IP%
echo.

REM Step 2: Update Flutter Config
echo [2/5] Updating Flutter configuration...

set CONFIG_FILE=lib\core\config\api_config.dart

if not exist "%CONFIG_FILE%" (
    echo [✗] ERROR: Config file not found!
    pause
    exit /b 1
)

REM Create timestamped backup
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul 2>&1

REM Update IP using PowerShell
powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'http://[\d.]+:8000', 'http://%IP%:8000' | Set-Content '%CONFIG_FILE%'" 2>nul

echo [✓] Configuration updated: http://%IP%:8000
echo.

REM Step 3: Check Django
echo [3/5] Checking Django backend...

if not exist "backend\manage.py" (
    echo [✗] ERROR: Django backend not found!
    pause
    exit /b 1
)

echo [✓] Django backend found
echo.

REM Step 4: Check if port 8000 is already in use
echo [4/5] Checking if port 8000 is available...

netstat -ano | findstr :8000 >nul 2>&1
if %errorlevel%==0 (
    echo [!] WARNING: Port 8000 is already in use!
    echo.
    set /p KILL="Kill existing process? (Y/N): "
    
    if /i "!KILL!"=="Y" (
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
            taskkill /PID %%a /F >nul 2>&1
        )
        echo [✓] Port cleared
        timeout /t 2 >nul
    )
) else (
    echo [✓] Port 8000 is available
)

echo.

REM Step 5: Display startup options
echo [5/5] Ready to start!
echo.
echo ========================================================================
echo                         STARTUP OPTIONS
echo ========================================================================
echo.
echo [1] Start Django Server Only
echo [2] Start Django Server + Flutter App
echo [3] Show Server URLs and Exit
echo [4] Exit
echo.
set /p OPTION="Select option (1-4): "

if "%OPTION%"=="1" goto start_django
if "%OPTION%"=="2" goto start_both
if "%OPTION%"=="3" goto show_urls
if "%OPTION%"=="4" goto end

:start_django
echo.
echo ========================================================================
echo                    STARTING DJANGO SERVER
echo ========================================================================
echo.
echo Server URL: http://%IP%:8000
echo Admin Panel: http://%IP%:8000/admin
echo API Docs: http://%IP%:8000/swagger
echo.
echo Press Ctrl+C to stop the server
echo ========================================================================
echo.
cd backend
python manage.py runserver 0.0.0.0:8000
goto end

:start_both
echo.
echo ========================================================================
echo              STARTING DJANGO SERVER + FLUTTER APP
echo ========================================================================
echo.
echo Opening Django server in new window...
start "Efatha Django Server" cmd /k "cd backend && python manage.py runserver 0.0.0.0:8000"

echo Waiting for server to start...
timeout /t 5 >nul

echo.
echo Starting Flutter app...
flutter run

goto end

:show_urls
echo.
echo ========================================================================
echo                       SERVER INFORMATION
echo ========================================================================
echo.
echo Backend Server: http://%IP%:8000
echo.
echo API Endpoints:
echo   - Register:    http://%IP%:8000/api/auth/register/
echo   - Login:       http://%IP%:8000/api/auth/login-password/
echo   - Profile:     http://%IP%:8000/api/auth/users/me/
echo   - Admin Panel: http://%IP%:8000/admin/
echo   - API Docs:    http://%IP%:8000/swagger/
echo.
echo Flutter Config: %CONFIG_FILE%
echo.
echo To start manually:
echo   Backend:  cd backend && python manage.py runserver 0.0.0.0:8000
echo   Flutter:  flutter run
echo.
echo ========================================================================
pause
goto end

:end
endlocal
