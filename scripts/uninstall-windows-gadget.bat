@echo off
setlocal

set "TRIAL_GADGET_NAME=Wrapped_Tapered_Spiral_Surfacing_Toolpath"
set "FOUND=0"

echo.
echo Removing installed Vectric gadget: %TRIAL_GADGET_NAME%
echo Close VCarve before running this script.
echo.

call :RemoveIfExists "%PUBLIC%\Documents\Vectric Files\Gadgets\VCarve Pro Trial Edition V12.5\%TRIAL_GADGET_NAME%"

echo.
if "%FOUND%"=="0" (
  echo No installed copy was found at:
  echo   %PUBLIC%\Documents\Vectric Files\Gadgets\VCarve Pro Trial Edition V12.5\%TRIAL_GADGET_NAME%
) else (
  echo Done. You can now install the latest .vgadget from the NAS.
)
echo.
exit /b

:RemoveIfExists
set "TARGET=%~1"
if exist "%TARGET%\" (
  set "FOUND=1"
  echo Deleting "%TARGET%"
  rmdir /s /q "%TARGET%"
  if exist "%TARGET%\" (
    echo Failed to delete "%TARGET%"
    echo Try running this script as Administrator, or confirm VCarve is closed.
  ) else (
    echo Deleted "%TARGET%"
  )
)
exit /b
