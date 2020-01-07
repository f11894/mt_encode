title encode job %3
%avs2pipemod64% -trim=%1,%2 -y4mp %avs_file% | %aomenc% %libaom_option% --ivf --passes=2 --pass=1 --fpf="%TemporaryDir%%random32%_video%3.fpf" -o "%TemporaryDir%%random32%_video%3.%video_extension%" -
%avs2pipemod64% -trim=%1,%2 -y4mp %avs_file% | %aomenc% %libaom_option% --ivf --passes=2 --pass=2 --fpf="%TemporaryDir%%random32%_video%3.fpf" -o "%TemporaryDir%%random32%_video%3.%video_extension%" -
if not "%ERRORLEVEL%"=="0" pause
del "%TemporaryDir%%random32%_video%3.fpf"
exit
