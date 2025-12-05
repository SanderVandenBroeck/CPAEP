vlib work
vlog +cover +acc -sv -f flists/tb_big_mac_gemm.flist +incdir+.
vsim -voptargs="+acc" -coverage work.tb_big_mac_gemm
add wave -r /*
run -all
