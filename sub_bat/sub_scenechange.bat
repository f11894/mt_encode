cd "%TemporaryDir%"
title scenechange job %3
%ffprobe% -select_streams v -show_entries frame=pkt_pts -of compact=p=0:nk=1 -f lavfi "movie=%~nx1,setpts=N+1,select=gt(scene\,%Scene_change_threshold%)">"%~dpn1_temp.txt" 2>nul
if not "%ERRORLEVEL%"=="0" pause
setlocal
if exist "%~dpn1_temp.txt" for %%i in ("%~dpn1_temp.txt") do if not "%%~zi"=="0" set scenechange=true
if "%scenechange%"=="true" for /f "delims=" %%a in ('type "%~dpn1_temp.txt"') do (
    set /a "correction_num=%%a + %~2"
    call set /p x="%%correction_num%%"<nul >>"%~dpn1.txt"
    echo,>>"%~dpn1.txt"
)
endlocal
del "%~dpn1_temp.txt" 
del "%~1"
exit
