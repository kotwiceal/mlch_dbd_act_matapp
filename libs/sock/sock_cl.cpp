#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <stdio.h>
#include "CL_DLL_Interface.cpp"

#pragma comment(lib, "WS2_32.lib")

extern "C" __declspec(dllexport) int send_packet(const char* address, int port, const char* packet) {
    SOCKET sock_cl = INVALID_SOCKET; WSADATA wsaData; int info_result;

    struct sockaddr_in sock_addr;
        sock_addr.sin_family = AF_INET;
        sock_addr.sin_port = htons(port);
        sock_addr.sin_addr.s_addr = inet_addr(address);

    info_result = WSAStartup(MAKEWORD(2, 0), &wsaData);
    if (info_result != 0) {
        printf("WSAStartup failed with error: %d\n", info_result);
        return 1;
    }

    sock_cl = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_cl == INVALID_SOCKET) {
        printf("socket failed with error: %ld\n", WSAGetLastError());
        return 1;
    }

    info_result = connect(sock_cl, (struct sockaddr*)&sock_addr, sizeof(sock_addr));
    if (info_result == SOCKET_ERROR) {
        printf("connect failed with error: %ld\n", WSAGetLastError());
        closesocket(sock_cl);
        WSACleanup();
        return 1;
    }

    info_result = send(sock_cl, packet, (int) strlen(packet), 0);
    if (info_result == SOCKET_ERROR) {
        printf("send failed with error: %d\n", WSAGetLastError());
        closesocket(sock_cl);
        WSACleanup();
        return 1;
    }

    info_result = shutdown(sock_cl, SD_SEND);
    if (info_result == SOCKET_ERROR) {
        printf("shutdown failed with error: %d\n", WSAGetLastError());
        closesocket(sock_cl);
        WSACleanup();
        return 1;
    }

    closesocket(sock_cl);
    WSACleanup();

    return 0;
}

extern "C" __declspec(dllexport) int davis_tcp_transmitter(int* parsInt, float* parsFloat, char** parsString) {
    const int port = parsInt[0];
    const char* address = (const char*) parsString[0];
    const char* packet = parsString[1];
    send_packet(address, port, packet);
    return 0;
}

void test_function() {
    const char* address = "192.168.0.176"; int port = 6060; const char* packet = "test_function()";
    send_packet(address, port, packet);
}


int main() {
    test_function();
    return 0;
}