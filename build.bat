@echo off

pushd %~dp0

set exe_name=snake_ai
set collections=

:: Release build config
set level=speed
set dir=release
set debug_flag=
set vet_flag=

if "%1"=="debug" (
    :: Debug build config
    set level=minimal
    set dir=debug
    set exe_name=%exe_name%_d
    set debug_flag=-debug
)

if "%2"=="vet" (
    set vet_flag=-vet
)

echo Building %dir% binary...
if not exist "build\%dir%\" mkdir "build\%dir%\"

odin build snake_ai -out:"build\%dir%\%exe_name%.exe" %collections% -o:%level% -microarch:native %debug_flag% %vet_flag% -show-timings

popd
