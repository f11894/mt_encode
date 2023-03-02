if exist "%TemporaryDir%%SHA1%_video%3.txt" exit
%avs2pipemod64% -trim=%1,%2 -y4mp %avs_file% 2>nul | %vpxenc% %libvpx_option% --ivf --passes=2 --pass=1 --fpf="%TemporaryDir%%SHA1%_video%3.fpf" -o "%TemporaryDir%%SHA1%_video%3.%video_extension%" - >nul 2>&1
%avs2pipemod64% -trim=%1,%2 -y4mp %avs_file% 2>nul | %vpxenc% %libvpx_option% --ivf --passes=2 --pass=2 --fpf="%TemporaryDir%%SHA1%_video%3.fpf" -o "%TemporaryDir%%SHA1%_video%3.%video_extension%" - >nul 2>&1
if not "%ERRORLEVEL%"=="0" echo エンコードに失敗しました
del "%TemporaryDir%%SHA1%_video%3.fpf"
echo done>"%TemporaryDir%%SHA1%_video%3.txt"
title Progress %3/%job_num%
exit
