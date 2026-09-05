cl /nologo /c /Zi /Fo:./ ../wrapper/asiodrivers_c_wrapper.cpp ../host\pc\asiolist.cpp ../host\asiodrivers.cpp ../common\asio.cpp /I../common /I../host/pc /I../host

lib /nologo /out:asio.lib *.obj
