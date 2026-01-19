@echo off
echo.
echo ============================================
echo    Efatha Church Backend - Quick Start
echo ============================================
echo.
echo Starting Django development server...
echo.
echo Backend will be available at:
echo   - API: http://localhost:8000/api/
echo   - Admin: http://localhost:8000/admin/
echo   - Swagger: http://localhost:8000/swagger/
echo.
echo For Flutter app, use your computer's IP:
echo   Find your IP: ipconfig
echo   Update in: lib/core/config/api_config.dart
echo.
echo Press Ctrl+C to stop the server
echo.
echo ============================================
echo.

cd /d %~dp0
call venv\Scripts\activate.bat
python manage.py runserver 0.0.0.0:8000
