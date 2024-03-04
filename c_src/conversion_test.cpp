

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#ifdef _WIN32
    #include <io.h>
#elif __linux__
    #include <inttypes.h>
    #include <unistd.h>
    #define __int64 int64_t
    #define _close close
    #define _read read
    #define _lseek64 lseek64
    #define _O_RDONLY O_RDONLY
    #define _open open
    #define _lseeki64 lseek64
    #define _lseek lseek
    #define stricmp strcasecmp
#endif
#include <unistd.h>

#include "fm_radio.h"
#include "audio.h"

using namespace std;

int main(int argc, char **argv)
{
    // printf yo shit here
    // printf("QUANTIZE_F(PI) = %08x\n", QUANTIZE_F(PI));
    // printf("QUANTIZE_F(MAX_DEV) = %08x\n", QUANTIZE_F(MAX_DEV));
    // printf("QUANTIZE_F(TAU) = %08x\n", QUANTIZE_F(TAU));
    // printf("QUANTIZE_F(W_PP) = %08x\n", QUANTIZE_F(W_PP));
    printf("QUANTIZE_F(PI / 4.0) = %08x\n", QUANTIZE_F(PI / 4.0));
    printf("QUANTIZE_F(3.0 * PI / 4.0) = %08x\n", QUANTIZE_F(3.0 * PI / 4.0));
    printf("DEQUANTIZE(ffffc392) = %08x\n", DEQUANTIZE(0xffffc392));
    printf("FM_DEMOD_GAIN = %08x\n", QUANTIZE_F( (float)QUAD_RATE / (2.0f * PI * MAX_DEV) ));
    

    return 0;
}

