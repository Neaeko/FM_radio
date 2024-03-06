
#include <stdio.h>
#include <stdlib.h>
#include <sys/soundcard.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <io.h>
#include <unistd.h>

#include "audio.h"

using namespace std;


int audio_init(int sampling_rate, const std::string device_name)
{
    string dev_name = !device_name.empty() ? device_name : "/dev/dsp";

    int fd = open( dev_name.c_str(), O_WRONLY );
    if ( fd < 0)
    {
        printf( "Failed to open device %s", dev_name.c_str() );
        return -1;
    }

    int format = AFMT_S16_NE;
    int orig_format = format;
    if ( ioctl(fd, SNDCTL_DSP_SETFMT, &format) < 0 )
    {
        printf ( "ioctl failed for device %s.\n", dev_name.c_str() );
        return -1;
    }
    else if ( format != orig_format )
    {
        printf( "Unable to support format %d. Card requested %d instead.\n", orig_format, format );
        return -1;
    }

    // set to stereo no matter what.  Some hardware only does stereo
    int channels = 2;
    if ( ioctl(fd, SNDCTL_DSP_CHANNELS, &channels) < 0 || channels != 2 )
    {
        printf( "Unable to set STEREO mode.\n" );
        return -1;
    }

    // set sampling freq
    int sf = sampling_rate;
    if ( ioctl(fd, SNDCTL_DSP_SPEED, &sf) < 0 )
    {
        printf( "Invalid sampling rate for device %s: %d\n", dev_name.c_str(), sf );
        return -1;
    }

    return fd;
}



void audio_tx( int fd, int sampling_rate, int *lt_channel, int *rt_channel, int n_samples )
{
    double CHUNK_TIME = 0.005;
    int chunk_size = (int)(sampling_rate * CHUNK_TIME);
    short * buffer = new short[chunk_size * 2];

    for (int i = 0; i < n_samples; i += chunk_size)
    {
        for (int j = 0; j < chunk_size; j++)
        {
            buffer[2*j+0] = (short)lt_channel[j];
            buffer[2*j+1] = (short)rt_channel[j];
        }

        lt_channel += chunk_size;
        rt_channel += chunk_size;
        
        if ( write(fd, buffer, 2*chunk_size*sizeof(short)) < 0 )
        {
            printf( "Failed to write audio output!\n" );
            return;
        }
    }

    delete buffer;
}
