// execute dll tcp socket client that connects to tpc server;
string dll_name = ".\libs\sock\sock_cl.dll";
string function_name = "davis_tcp_transmitter";

int parsInt[1] = {7070}; // port;
float parsFloat[1] = {0}; // temporary;
string parsString[2] = {"192.168.0.176", "start"}; // ip address & state event data;
int result  = CallDllEx(dll_name, function_name, parsInt, parsFloat, parsString);