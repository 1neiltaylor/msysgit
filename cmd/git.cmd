@setlocal
@for /F "delims=" %%I in ("%~dp0..") do @set path=%%~fI\bin;%%~fI\mingw\bin;%PATH%
@if "%HOME%"=="" @set HOME=%USERPROFILE%
@git.exe %*
@exit /b %ErrorLevel%
