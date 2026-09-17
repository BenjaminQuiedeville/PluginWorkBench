cl /nologo /c /Zi /MP /Fo:./ /D WINDOWS /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_CRT_SECURE_NO_DEPRECATE" ../wrapper/asiodrivers_c_wrapper.cpp ../host\pc\asiolist.cpp ../host\asiodrivers.cpp ../common\asio.cpp /I../common /I../host/pc /I../host

lib /nologo /out:asio.lib *.obj

copy asio.lib ..\..\..\source\asio\asio.lib
