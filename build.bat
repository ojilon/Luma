@echo off
set ODIN=D:\Dev\Odin\odin.exe
if not exist "%ODIN%" set ODIN=odin
cd /d %~dp0

if "%1"=="" (
    echo Building Luma: The Wandering Leaf debug build...
    "%ODIN%" build . -debug -out:build\Luma.exe
    if errorlevel 1 (
        echo.
        echo BUILD FAILED.
        exit /b 1
    )
    echo.
    echo Build complete: build\Luma.exe
    echo Run: build\Luma.exe
    exit /b 0
)

if /i "%1"=="run" (
    echo Building and running Luma...
    "%ODIN%" build . -debug -out:build\Luma.exe
    if errorlevel 1 (
        echo BUILD FAILED.
        exit /b 1
    )
    build\Luma.exe
    exit /b %errorlevel%
)

if /i "%1"=="clean" (
    if exist build rd /s /q build
    echo Cleaned.
    exit /b 0
)

echo Usage: build.bat       - build debug executable
echo        build.bat run   - build and run
echo        build.bat clean - remove build output
exit /b 0
