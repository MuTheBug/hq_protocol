@echo off
REM ============================================================
REM جمعية حقّنا - HAQQUNA
REM Windows install + run script
REM ============================================================
REM Usage:
REM   run.bat              - full setup + run
REM   set PORT=9000 ^& run.bat   - run on different port
REM ============================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

if "%PORT%"=="" set PORT=8000
if "%HOST%"=="" set HOST=0.0.0.0
if "%VENV_DIR%"=="" set VENV_DIR=.venv

echo.
echo === HAQQUNA / jamiyat haqquna ===
echo.

REM ---- 1. Check Python ----
echo --- Checking Python ---
where python >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed. Please install Python 3.10 or newer.
    exit /b 1
)
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"
if errorlevel 1 (
    echo Error: Python 3.10+ required.
    exit /b 1
)
echo OK: Python found

REM ---- 2. Virtual env ----
if not "%NO_VENV%"=="1" (
    echo --- Virtual environment ---
    if not exist "%VENV_DIR%\Scripts\activate.bat" (
        echo Creating virtualenv in %VENV_DIR%...
        python -m venv "%VENV_DIR%"
        if errorlevel 1 (
            echo Failed to create venv. Try: set NO_VENV=1
            exit /b 1
        )
    )
    call "%VENV_DIR%\Scripts\activate.bat"
    echo OK: venv activated
)

REM ---- 3. Install dependencies ----
if not "%SKIP_DEPS%"=="1" (
    echo --- Installing requirements ---
    python -m pip install --quiet --upgrade pip
    python -m pip install --quiet -r requirements.txt
    if errorlevel 1 (
        echo Failed to install dependencies.
        exit /b 1
    )
    echo OK: requirements installed
) else (
    echo SKIPPED: dependencies
)

REM ---- 4. Migrate ----
echo --- Migrating database ---
python manage.py migrate --noinput
if errorlevel 1 exit /b 1

REM ---- 5. Admin account ----
echo --- Admin account ---
if defined ADMIN_PASSWORD (
    python manage.py create_admin --password "%ADMIN_PASSWORD%"
) else (
    python manage.py create_admin
)

REM ---- 6. Seed reference data ----
if not "%SKIP_SEED%"=="1" (
    echo --- Seeding reference data ---
    python manage.py seed_reference_data
)

REM ---- 7. Run server ----
echo.
echo ============================================================
echo   HAQQUNA - jamiyat haqquna
echo   URL:       http://%HOST%:%PORT%/
echo   Username:  admin
if defined ADMIN_PASSWORD (
    echo   Password:  %ADMIN_PASSWORD%
) else (
    echo   Password:  haqquna2026
)
echo   Admin:     http://%HOST%:%PORT%/admin/
echo.
echo   Press Ctrl+C to stop
echo ============================================================
echo.

python manage.py runserver %HOST%:%PORT%
