// set buffer shape;
int nx, nz, format, grid_spacing;
GetVectorBufferSize(theBuffer, nx, nz, format, grid_spacing);
InfoText("nx=" + nx + "; nz=" + nz + "; format=" + format + "; grid_spacing=" + grid_spacing + ";");

// define temporary variables;
int i, j;
float value, sum, array[nz];
// define pixel limits of velocity field
int xlim_min = 0, xlim_max = nz, zlim_min = 0, zlim_max = nx;

// build json string;
string json = "[";
for (i = xlim_min; i < xlim_max - 1; i++) {
    json = json + "["; array = R[theBuffer, i];
    for (j = zlim_min; j < zlim_max - 1; j++) {json = json + array[j] + ",";}
    j = xlim_max - 1; json = json + array[j] + "],";
}

i = xlim_max - 1; json = json + "["; array = R[theBuffer, i];
for (j = zlim_min; j < zlim_max - 1; j++) {json = json + array[j] + ",";}
j = xlim_max - 1; json = json + array[j] + "]";
json = json + "]";

// execute dll tcp socket client that connects to tpc server and send data;
string dll_name = ".\libs\sock\sock_cl.dll";
string function_name = "davis_tcp_transmitter";

int parsInt[1] = {6060}; // port;
float parsFloat[1] = {0}; // dummy data;
string parsString[2] = {"192.168.0.176", json}; // ip address & json data;
int result  = CallDllEx(dll_name, function_name, parsInt, parsFloat, parsString);