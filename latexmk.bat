@echo off
rem Local latexmk shim to force building via build-wrapper.ps1 (maps X:)
setlocal enabledelayedexpansion
set DOC=
for %%a in (%*) do (
  rem pick the first existing .tex file argument or last arg ending with .tex
  if "%%~xa"==".tex" set DOC=%%~a
  if exist "%%~a" set DOC=%%~a
)
if "%DOC%"=="" (
  rem fallback to main.tex in current dir
  set DOC=%CD%\main.tex
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-wrapper.ps1" "%DOC%"
endlocal
