@echo off
rem -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set xargs_threads=4
set Scene_change_threshold=0.45
set min_frame_division_interval=25
set max_frame_division_interval=250
set video_encoder=libvpx
set audio_extension=opus
set output_extension=mkv

set libaom_option=--cpu-used=1 --row-mt=1 --tile-columns=2 --tile-rows=2 --threads=4 --end-usage=q --cq-level=35 --kf-max-dist=250 --kf-min-dist=250
set libvpx_option=--cpu-used=1 --row-mt=1 --tile-columns=2 --tile-rows=2 --threads=4 --end-usage=q --cq-level=35 --kf-max-dist=250 --kf-min-dist=250 --auto-alt-ref=6
set libopus_option=-acodec libopus -b:a 128K -frame_duration 60
set qaac_option=-q 2 --tvbr 82

set timer64="%~dp0tools\timer64.exe"
set ffmpeg="%~dp0tools\ffmpeg.exe"
set ffprobe="%~dp0tools\ffprobe.exe"
set aomenc="%~dp0tools\aomenc.exe"
set vpxenc="%~dp0tools\vpxenc.exe"
set qaac=
set avs2pipemod64="%~dp0tools\avs2pipemod64.exe"
set busybox64="%~dp0tools\busybox64.exe"
rem -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
:start
if "%~1"=="" goto end
setlocal
if "%video_encoder%"=="libaom" set sub_bat="%~dp0sub_bat\sub_libaom.bat"&set video_extension=ivf
if "%video_encoder%"=="libvpx" set sub_bat="%~dp0sub_bat\sub_libvpx.bat"&set video_extension=ivf
if not defined sub_bat (
    echo エラー 無効なvideo_encoderです:"%video_encoder%"
    goto error_label
)
set "TemporaryDir=%~dp1Temporary\"
for /f "delims=" %%a in ('PowerShell "-Join (Get-Random -Count 32 -input 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z)"') do set "random32=%%a"
if not exist "%TemporaryDir%" mkdir "%TemporaryDir%"
set avs_file="%TemporaryDir%\%random32%.avs"
set audio_file="%TemporaryDir%%random32%_audio.%audio_extension%"
set xargs_txt="%TemporaryDir%\%random32%_xargs.txt"
set scenechange_txt="%TemporaryDir%\%random32%_scenechange.txt"
set concat_txt="%TemporaryDir%\%random32%_concat.txt"
if /i "%~x1"==".avs" (
    set avs_file="%~1"
    set input_avs=true
) else (
    echo LoadPlugin^("%~dp0tools\plugins64\LSMASHSource.dll"^)
    if /i "%~x1"==".mp4" (
        echo A = LSMASHAudioSource^("%~1"^)
        echo V = LSMASHVideoSource^("%~1"^)
    ) else (
        echo A = LWLibavAudioSource^("%~1"^)
        echo V = LWLibavVideoSource^("%~1"^)
    )
    echo AudioDub^(V, A^)
    set input_avs=false
)>%avs_file%
for %%i in (%avs2pipemod64%) do pushd "%%~dpi"
for /f "tokens=2" %%a in ('.\avs2pipemod64.exe -info %avs_file% ^| find "v:frames"') do set "frame_count=%%a"
%avs2pipemod64% -info %avs_file% 
popd
echo 音声のエンコードを開始 
if /i "%audio_extension%"=="opus" start "" /min %ffmpeg% -y -i %avs_file% -vn %libopus_option% %audio_file%
if /i "%audio_extension%"=="m4a"  start "" /min %comspec% /c "%ffmpeg% -y -loglevel quiet -i %avs_file% -vn -f wav - | %qaac% %qaac_option% --ignorelength -o %audio_file% "-" "
pushd "%TemporaryDir%"
echo シーンチェンジを検出中 
%ffprobe% -select_streams v -show_entries frame=pkt_pts -of compact=p=0:nk=1 -f lavfi "movie=%random32%.avs,setpts=N+1,select=gt(scene\,%Scene_change_threshold%)">%scenechange_txt% 2>nul
popd
set /a frame_count_plus_1=frame_count+1
echo %frame_count_plus_1% >>%scenechange_txt%
rem デバッグ用 
rem echo LanczosResize(320,180)>>%avs_file%
rem echo info()>>%avs_file%
set start_f=0
if not defined min_frame_division_interval set min_frame_division_interval=25
for /f "delims=" %%i in ('Type %scenechange_txt%') do (
    call :division %%i
)
:encode
echo 動画のエンコードを開始 
echo,
echo Video encoder           : %video_encoder%
echo Total number of jobs    : %job_num%
echo xargs threads           : %xargs_threads%
echo,
for %%i in (%timer64%) do pushd "%%~dpi"
for /f "tokens=3" %%a in ('.\timer64.exe %busybox64% xargs -a %xargs_txt% -n 3 -P %xargs_threads% %comspec% /c start "" /wait /min %sub_bat% ^| find "TotalMilliseconds"') do set "TotalMilliseconds=%%a"
popd
for /f "delims=" %%a in ('PowerShell "%TotalMilliseconds%/1000"') do set "TotalSeconds=%%a"
for /f "delims=" %%a in ('PowerShell "%frame_count%/%TotalSeconds%"') do set "enc_fps=%%a"
echo Elapsed time(sec)       : %TotalSeconds%
echo Total encoding fps      : %enc_fps%
echo,
pushd "%TemporaryDir%"
for /L %%i in (1,1,%job_num%) do echo file '%random32%_video%%i.%video_extension%'>>%concat_txt%
echo 動画と音声を結合します 
echo,
%ffmpeg% -y -hide_banner -f concat -safe 0 -i %concat_txt% -i %audio_file% -c copy "%~dpn1_%video_encoder%_%audio_extension%.%output_extension%"
if "%ERRORLEVEL%"=="0" (
    for /L %%i in (1,1,%job_num%) do del "%random32%_video%%i.%video_extension%"
    del %audio_file%
    del %concat_txt%
    del %scenechange_txt%
    del %xargs_txt%
    if "%input_avs%"=="false" del %avs_file%
)
echo,
popd
:error_label
endlocal
shift
goto start

:end
echo すべての処理が終了しました 
pause
exit /b

:division
set /a end_f=%1-2
set /a frame_distance=end_f-start_f+1
if %frame_distance% GTR %max_frame_division_interval% goto division2
if %frame_distance% GEQ %min_frame_division_interval% (
    set /a job_num=job_num+1
    call echo %start_f% %end_f% %%job_num%% >>%xargs_txt%
    set /a start_f=%1-1
)
exit /b

:division2
set /a job_num=job_num+1
set /a end_f_temp=start_f+max_frame_division_interval-1
echo %start_f% %end_f_temp% %job_num% >>%xargs_txt%
set /a start_f=start_f+max_frame_division_interval
set /a end_f_plus=end_f_temp+max_frame_division_interval
if %end_f_plus% GEQ %end_f% (
    set /a job_num=job_num+1
    call echo %start_f% %end_f% %%job_num%% >>%xargs_txt%
    set /a start_f=%1-1
    exit /b
)
goto division2
exit /b
