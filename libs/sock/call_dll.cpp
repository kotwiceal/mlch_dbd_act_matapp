#include <stdio.h>
#include <windows.h>
using namespace std;

void test_function() {
    const char* filename = "./libs/sock/sock_cl.dll", 
        *function_name = "send_packet";
    const char* address = "192.168.0.176"; int port = 6060; const char* packet = "call sock_cl.dll";
    typedef void (*pfunc)(const char*, int, const char*);

    HANDLE h = LoadLibraryA(filename);
    pfunc function = (pfunc) GetProcAddress(GetModuleHandleA(filename), function_name);
    function(address, port, packet);
}

int main() {
    test_function();
    return 0;
}