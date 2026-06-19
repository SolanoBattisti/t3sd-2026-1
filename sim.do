if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work rtl/memoria.sv
vlog -work work rtl/emulador_sensor.sv
vlog -work work rtl/coletor_dados.sv
vlog -work work rtl/top.sv
vlog -work work tb/tb_top.sv

vsim -voptargs=+acc=lprn -t ns work.tb_top

run 10000000 ns