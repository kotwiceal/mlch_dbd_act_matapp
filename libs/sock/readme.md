To build dll file execute following command:
* C compiler
    ```
    gcc -o sock_cl.dll -s -shared sock_cl.cpp -W -lwsock32
    ```
* C++ compiler
  ```
    g++ -o sock_cl.dll -s -shared sock_cl.cpp -W -lwsock32
  ```
> Comment
`-lwsock32` is prefix to MinGW64 representing Windows Socket Library

