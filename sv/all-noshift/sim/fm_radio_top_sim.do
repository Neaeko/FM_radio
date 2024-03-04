setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "fm_radio_top_tb.sv"
vlog -work work "../sv/fm_radio_top.sv"
vlog -work work "../sv/demod.sv"
vlog -work work "../sv/divider.sv"
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/fir_complex.sv"
vlog -work work "../sv/fir_normal.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/iir_normal.sv" 
vlog -work work "../sv/multiplier_w_fifo.sv"



vsim -classdebug -voptargs=+acc +notimingchecks -L work work.fm_radio_top_tb -wlf fm_radio_top_tb.wlf

do fm_radio_top_wave.do

run -all
