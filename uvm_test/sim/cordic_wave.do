add wave -noupdate -group my_uvm_tb
add wave -noupdate -group my_uvm_tb -radix hexadecimal /my_uvm_tb/*

add wave -noupdate -group my_uvm_tb/dut
add wave -noupdate -group my_uvm_tb/dut -radix hexadecimal /my_uvm_tb/dut/*


add wave -noupdate -group my_uvm_tb/dut/fir_cmplx
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/in_rd_en
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/i_in
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/q_in


add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/real_sum
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/imag_sum
add wave -noupdate -group my_uvm_tb/dut/fir_cmplx -radix hexadecimal /my_uvm_tb/dut/fir_cmplx/out_full

add wave -noupdate -group my_uvm_tb/dut/demodulation_inst
add wave -noupdate -group my_uvm_tb/dut/demodulation_inst -radix hexadecimal my_uvm_tb/dut/demodulation_inst/*

add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr
add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/in_dout
add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/in_rd_en

add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/out_din
add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_bp_lmr -radix hexadecimal my_uvm_tb/dut/fir_bp_lmr/out_full


add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/in_dout
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/in_rd_en

add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/out_din
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_19 -radix hexadecimal my_uvm_tb/dut/fir_piolet_19/out_full


add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/in_dout
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/in_rd_en

add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/out_din
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_piolet_hp -radix hexadecimal my_uvm_tb/dut/fir_piolet_hp/out_full

add wave -noupdate -group my_uvm_tb/dut/mult
add wave -noupdate -group my_uvm_tb/dut/mult -radix hexadecimal my_uvm_tb/dut/mult/*

add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/in_dout
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/in_rd_en

add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/out_din
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lmr -radix hexadecimal my_uvm_tb/dut/fir_normal_lmr/out_full


add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/in_empty
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/in_dout
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/in_rd_en

add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/out_din
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/out_wr_en
add wave -noupdate -group my_uvm_tb/dut/fir_normal_lpr -radix hexadecimal my_uvm_tb/dut/fir_normal_lpr/out_full




add wave -noupdate -group my_uvm_tb/dut/IIR_left
add wave -noupdate -group my_uvm_tb/dut/IIR_left -radix hexadecimal my_uvm_tb/dut/IIR_left/*


add wave -noupdate -group my_uvm_tb/dut/IIR_right
add wave -noupdate -group my_uvm_tb/dut/IIR_right -radix hexadecimal my_uvm_tb/dut/IIR_right/*


add wave -noupdate -group my_uvm_tb/dut/gain_32_left
add wave -noupdate -group my_uvm_tb/dut/gain_32_left -radix hexadecimal my_uvm_tb/dut/gain_32_left/*

add wave -noupdate -group my_uvm_tb/dut/gain_32_right
add wave -noupdate -group my_uvm_tb/dut/gain_32_right -radix hexadecimal my_uvm_tb/dut/gain_32_right/*




