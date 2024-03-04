
#ifndef __AUDIO_H__
#define __AUDIO_H__

#include <string>

int audio_init(int sampling_rate, const std::string device_name = "" );

void audio_tx( int fd, int sampling_rate, int *lt_channel, int *rt_channel, int n_samples );

#endif
