

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <iomanip>
#include <iostream>
#include <fstream>

#include "fm_radio.h"



void fm_radio_stereo(unsigned char *IQ, int *left_audio, int *right_audio)
{
    // static input/output arrays
    static int I[SAMPLES];
    static int Q[SAMPLES];
    static int I_fir[SAMPLES];
    static int Q_fir[SAMPLES];
    static int demod[SAMPLES];
    static int bp_pilot_filter[SAMPLES];
    static int bp_lmr_filter[SAMPLES];
    static int hp_pilot_filter[SAMPLES];
    static int audio_lpr_filter[AUDIO_SAMPLES];
    static int audio_lmr_filter[AUDIO_SAMPLES];
    static int square[SAMPLES];
    static int multiply[SAMPLES];
    static int left[AUDIO_SAMPLES];
    static int right[AUDIO_SAMPLES];
    static int left_deemph[AUDIO_SAMPLES];
    static int right_deemph[AUDIO_SAMPLES];
    
    // static internal arrays
    static int fir_cmplx_x_real[MAX_TAPS];
    static int fir_cmplx_x_imag[MAX_TAPS];
    static int demod_real[] = {0};
    static int demod_imag[] = {0};
    static int fir_lpr_x[MAX_TAPS];
    static int fir_lmr_x[MAX_TAPS];
    static int fir_bp_x[MAX_TAPS];
    static int fir_pilot_x[MAX_TAPS];
    static int fir_hp_x[MAX_TAPS];
    static int deemph_l_x[MAX_TAPS];
    static int deemph_l_y[MAX_TAPS];
    static int deemph_r_x[MAX_TAPS];
    static int deemph_r_y[MAX_TAPS];


    // f(t) = k * m(t) + fc
    //        m(t): the input signal
    //        k: constant that controls the frequency sensitivity 
    //        fc: the frequency of the carrier 
    // To recover m(t), two steps are needed:
    //    (1) Remove the carrier fc. This is already done in the USRP. 
    //    (2) Compute the instantaneous frequency of the baseband signal.

    // read the I/Q data from the buffer
    read_IQ( IQ, I, Q, SAMPLES );

    // Channel low-pass filter cuts off all frequnties above 80 Khz
    fir_cmplx_n( I, Q, SAMPLES, CHANNEL_COEFFS_REAL, CHANNEL_COEFFS_IMAG, fir_cmplx_x_real, fir_cmplx_x_imag, CHANNEL_COEFF_TAPS, 1, I_fir, Q_fir ); 

    // demodulate
    demodulate_n( I_fir, Q_fir, demod_real, demod_imag, SAMPLES, FM_DEMOD_GAIN, demod );

    // L+R low-pass FIR filter - reduce sampling rate from 256 KHz to 32 KHz
    fir_n( demod, SAMPLES, AUDIO_LPR_COEFFS, fir_lpr_x, AUDIO_LPR_COEFF_TAPS, AUDIO_DECIM, audio_lpr_filter ); 

    // L-R band-pass filter extracts the L-R channel from 23kHz to 53kHz
    fir_n1( demod, SAMPLES, BP_LMR_COEFFS, fir_bp_x, BP_LMR_COEFF_TAPS, 1, bp_lmr_filter ); 

    // Pilot band-pass filter extracts the 19kHz pilot tone
    fir_n2( demod, SAMPLES, BP_PILOT_COEFFS, fir_pilot_x, BP_PILOT_COEFF_TAPS, 1, bp_pilot_filter ); 

    // square the pilot tone to get 38kHz
    multiply_n( bp_pilot_filter, bp_pilot_filter, SAMPLES, square );

    // high-pass filter removes the tone at 0Hz created after the pilot tone is squared
    fir_n3( square, SAMPLES, HP_COEFFS, fir_hp_x, HP_COEFF_TAPS, 1, hp_pilot_filter ); 

    // demodulate the L-R channel from 38kHz to baseband
    multiply_n1( hp_pilot_filter, bp_lmr_filter, SAMPLES, multiply );

    // L-R low-pass FIR filter - reduce sampling rate from 256 KHz to 32 KHz
    fir_n4( multiply, SAMPLES, AUDIO_LMR_COEFFS, fir_lmr_x, AUDIO_LMR_COEFF_TAPS, AUDIO_DECIM, audio_lmr_filter ); 

    // Left audio channel - (L+R) + (L-R) = 2L 
    add_n( audio_lpr_filter, audio_lmr_filter, AUDIO_SAMPLES, left );

    // Right audio channel - (L+R) - (L-R) = 2R
    sub_n( audio_lpr_filter, audio_lmr_filter, AUDIO_SAMPLES, right );

    // Left channel deemphasis
    deemphasis_n( left, deemph_l_x, deemph_l_y, AUDIO_SAMPLES, left_deemph );

    // Right channel deemphasis
    deemphasis_n1( right, deemph_r_x, deemph_r_y, AUDIO_SAMPLES, right_deemph );

    // Left volume control
    gain_n( left_deemph, AUDIO_SAMPLES, VOLUME_LEVEL, left_audio );

    // Right volume control
    gain_n1( right_deemph, AUDIO_SAMPLES, VOLUME_LEVEL, right_audio );
}


void read_IQ( unsigned char *IQ, int *I, int *Q, int samples )
{
    int i = 0;
    FILE *out = fopen("1.0_read_IQ_output.txt", "w");
    for ( i = 0; i < samples; i++ )
    {
        I[i] = QUANTIZE_I((short)(IQ[i*4+1] << 8) | (short)IQ[i*4+0]);
        Q[i] = QUANTIZE_I((short)(IQ[i*4+3] << 8) | (short)IQ[i*4+2]);
        fprintf(out, "%08X%08X\n", I[i], Q[i]);


    }
    //fclose(out);

    
}

void demodulate_n( int *real, int *imag, int *real_prev, int *imag_prev, const int n_samples, const int gain, int *demod_out )
{
    int i = 0;
    //FILE *out1 = fopen("1.2_demod_real.txt", "w");
    FILE *out2 = fopen("1.2_demod_out.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        demodulate( real[i], imag[i], real_prev, imag_prev, gain, &demod_out[i] );
        //fprintf(out1, "%08X\n", real[i]);
        fprintf(out2, "%08X\n", demod_out[i]);
    }
}


void demodulate( int real, int imag, int *real_prev, int *imag_prev, const int gain, int *demod_out )
{
    // k * atan(c1 * conj(c0))
    int r = DEQUANTIZE(*real_prev * real) - DEQUANTIZE(-*imag_prev * imag);
    int i = DEQUANTIZE(*real_prev * imag) + DEQUANTIZE(-*imag_prev * real);
    
    *demod_out = DEQUANTIZE(gain * qarctan(i, r));

    // update the previous values
    *real_prev = real;
    *imag_prev = imag;
}

int qarctan(int y, int x)
{
    const int quad1 = QUANTIZE_F(PI / 4.0);
    const int quad3 = QUANTIZE_F(3.0 * PI / 4.0);

    int abs_y = abs(y) + 1;
    int angle = 0; 
    int r = 0;

    if ( x >= 0 ) 
    {
        r = QUANTIZE_I(x - abs_y) / (x + abs_y);
        angle = quad1 - DEQUANTIZE(quad1 * r);
    } 
    else 
    {
        r = QUANTIZE_I(x + abs_y) / (abs_y - x);
        angle = quad3 - DEQUANTIZE(quad1 * r);
    }

    return ((y < 0) ? -angle : angle);     // negate if in quad III or IV
}
void deemphasis_n( int *input, int *x, int *y, const int n_samples, int *output )
{
    iir_n( input, n_samples, IIR_X_COEFFS, IIR_Y_COEFFS, x, y, IIR_COEFF_TAPS, 1, output );
}

void deemphasis_n1( int *input, int *x, int *y, const int n_samples, int *output )
{
    iir_n1( input, n_samples, IIR_X_COEFFS, IIR_Y_COEFFS, x, y, IIR_COEFF_TAPS, 1, output );
}


void iir_n( int *x_in, const int n_samples, const int *x_coeffs, const int *y_coeffs, int *x, int *y, const int taps, int decimation, int *y_out )
{
    int i = 0;
    int j = 0;

    int n_elements = n_samples / decimation;
    FILE *out = fopen("1.7_demph_left.txt", "w");
    for ( ; i < n_elements; i++, j+=decimation )
    {
        iir( &x_in[j], x_coeffs, y_coeffs, x, y, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}

void iir_n1( int *x_in, const int n_samples, const int *x_coeffs, const int *y_coeffs, int *x, int *y, const int taps, int decimation, int *y_out )
{
    int i = 0;
    int j = 0;

    int n_elements = n_samples / decimation;
    FILE *out = fopen("2.7_demph_right.txt", "w");
    for ( ; i < n_elements; i++, j+=decimation )
    {
        iir( &x_in[j], x_coeffs, y_coeffs, x, y, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}



void iir( int *x_in, const int *x_coeffs, const int *y_coeffs, int *x, int *y, const int taps, const int decimation, int *y_out )
{
    int y1 = 0;
    int y2 = 0;
    int i = 0;
    int j = 0;
    
    // shift x 
    for ( j = taps-1; j > decimation-1; j-- ) 
    {
        x[j] = x[j-decimation];
    }

    for ( i = 0; i < decimation; i++ )
    {
        x[decimation-i-1] = x_in[i];
    }

    // shift y 
    for ( j = taps-1; j > 0; j--)
    {
        y[j] = y[j-1];
    }

    // get the new y
    for ( i = 0; i < taps; i++ )
    {
        y1 += DEQUANTIZE( x_coeffs[i] * x[i] );
        y2 += DEQUANTIZE( y_coeffs[i] * y[i] );
    }

    y[0] = y1 + y2;
        
    *y_out = y[taps-1];
}


void fir_n( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    FILE *out = fopen("2.6_fir_lpr_lowpass.txt", "w");
    int n_elements = n_samples / decimation;
    for ( i = 0; i < n_elements; i++, j+=decimation )
    {
        fir( &x_in[j], coeff, x, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}

void fir_n1( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    FILE *out = fopen("1.3_fir_lmr_bandpass.txt", "w");
    int n_elements = n_samples / decimation;
    for ( i = 0; i < n_elements; i++, j+=decimation )
    {
        fir( &x_in[j], coeff, x, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}

void fir_n2( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    FILE *out = fopen("2.1_fir_pilot.txt", "w");
    int n_elements = n_samples / decimation;
    for ( i = 0; i < n_elements; i++, j+=decimation )
    {
        fir( &x_in[j], coeff, x, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}

void fir_n3( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    FILE *out = fopen("2.3_fir_pilot_hp.txt", "w");
    int n_elements = n_samples / decimation;
    for ( i = 0; i < n_elements; i++, j+=decimation )
    {
        fir( &x_in[j], coeff, x, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}

void fir_n4( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    FILE *out = fopen("1.5_fir_lmr_lowpass.txt", "w");
    int n_elements = n_samples / decimation;
    for ( i = 0; i < n_elements; i++, j+=decimation )
    {
        fir( &x_in[j], coeff, x, taps, decimation, &y_out[i] );
        fprintf(out, "%08X\n", y_out[i]);
    }
}


void fir( int *x_in, const int *coeff, int *x, const int taps, const int decimation, int *y_out ) 
{
    int i = 0;
    int j = 0;
    int y = 0;
    
    // shift x
    for ( j = taps-1; j > decimation-1; j-- ) 
    {
        x[j] = x[j-decimation];
    }

    for ( i = 0; i < decimation; i++ )
    {
        x[decimation-i-1] = x_in[i];
    }

    for ( j = 0; j < taps; j++ ) 
    {
        y += DEQUANTIZE( coeff[taps-j-1] * x[j] );
    }
    
    *y_out = y;
}

void fir_cmplx_n( int *x_real_in, int *x_imag_in, const int n_samples, const int *h_real, const int *h_imag,
                  int *x_real, int *x_imag, const int taps, const int decimation, int *y_real_out, int *y_imag_out ) 
{
    int i = 0;
    int j = 0;

    int n_elements = n_samples / decimation;
    FILE *out1 = fopen("1.1_fir_cmplx_real.txt", "w");
    FILE *out2 = fopen("1.1_fir_cmplx_imag.txt", "w");
    for ( ; i < n_elements; i++, j+=decimation )
    {
        fir_cmplx( &x_real_in[j], &x_imag_in[j], h_real, h_imag, x_real, x_imag, taps, decimation, &y_real_out[i], &y_imag_out[i] );
        fprintf(out1, "%08X\n", y_real_out[i]);
        fprintf(out2, "%08X\n", y_imag_out[i]);
    }
}

void fir_cmplx( int *x_real_in, int *x_imag_in, const int *h_real, const int *h_imag, int *x_real, int *x_imag,
                const int taps, const int decimation, int *y_real_out, int *y_imag_out )
{
    int i = 0;
    int j = 0;
    int y_real = 0;
    int y_imag = 0;

    // shift x
    for ( j = taps-1; j > decimation-1; j-- ) 
    {
        x_real[j] = x_real[j-decimation];
        x_imag[j] = x_imag[j-decimation];
    }

    for ( i = 0; i < decimation; i++ )
    {
        x_real[decimation-i-1] = x_real_in[i];
        x_imag[decimation-i-1] = x_imag_in[i];
    }

    // compute new real & imag values
    for ( i = 0; i < taps; i++ )
    {
        y_real += DEQUANTIZE((h_real[i] * x_real[i]) - (h_imag[i] * x_imag[i]));
        y_imag += DEQUANTIZE((h_real[i] * x_imag[i]) - (h_imag[i] * x_real[i]));
        

    }

    *y_real_out = y_real;
    *y_imag_out = y_imag;
}

void multiply_n( int *x_in, int *y_in, const int n_samples, int *output )
{
    int i = 0;
    FILE *out = fopen("2.2_pilot_squared.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = DEQUANTIZE( x_in[i] * y_in[i] );
        fprintf(out, "%08X\n", output[i]);
    }
}

void multiply_n1( int *x_in, int *y_in, const int n_samples, int *output )
{
    int i = 0;
    FILE *out = fopen("1.4_left_mult.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = DEQUANTIZE( x_in[i] * y_in[i] );
        fprintf(out, "%08X\n", output[i]);
    }
}


void add_n( int *x_in, int *y_in, const int n_samples, int *output )
{
    int i = 0;
    FILE *out = fopen("1.6_left_add.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = x_in[i] + y_in[i];
        fprintf(out, "%08X\n", output[i]);
    }
}

void sub_n( int *x_in, int *y_in, const int n_samples, int *output )
{
    int i = 0;
    FILE *out = fopen("2.6_right_sub.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = x_in[i] - y_in[i];
        fprintf(out, "%08X\n", output[i]);
    }
}

void gain_n( int *input, const int n_samples, int gain, int *output )
{
    int i = 0;
    FILE *out = fopen("1.8_out_left.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = DEQUANTIZE(input[i] * gain) << (14-BITS);
        fprintf(out, "%08X\n", output[i]);
    }
}


void gain_n1( int *input, const int n_samples, int gain, int *output )
{
    int i = 0;
    FILE *out = fopen("2.8_out_right.txt", "w");
    for ( i = 0; i < n_samples; i++ )
    {
        output[i] = DEQUANTIZE(input[i] * gain) << (14-BITS);
        fprintf(out, "%08X\n", output[i]);
    }
}


