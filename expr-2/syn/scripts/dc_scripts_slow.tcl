#===========================================================================
# dc_scripts_slow.tcl — Synthesis with relaxed timing (40ns / 25MHz)
#===========================================================================

exec mkdir -p ./mapped ./rpt ./unmapped ./work
define_design_lib WORK -path ./work
set_app_var alib_library_analysis_path ./work

puts "============================================"
puts "  MiniRV CPU Logic Synthesis (RELAXED: 25MHz)"
puts "============================================"

set sv_files [glob ./rtl/*.sv]
analyze -work WORK -format sverilog $sv_files
elaborate cpu_pad -work WORK
current_design cpu_pad
link
write -hierarchy -format ddc -output ./unmapped/cpu_pad_unmapped_slow.ddc

set lib_name typical_1v2c25

set CLK_PERIOD     40.0
set CLK_UNCERTAINTY 0.5
set CLK_PORT       clk_pad

create_clock -period $CLK_PERIOD -name main_clk [get_ports $CLK_PORT]
set_clock_uncertainty $CLK_UNCERTAINTY [get_clocks main_clk]

puts "\[INFO\] Clock: $CLK_PORT, period=${CLK_PERIOD}ns, uncertainty=${CLK_UNCERTAINTY}ns"

set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set all_inputs_no_clk_rst [remove_from_collection $all_inputs_no_clk [get_ports rst_n_pad]]
set_driving_cell -library $lib_name -lib_cell AND2X4 $all_inputs_no_clk_rst
set_input_delay 0.2 -max -clock main_clk $all_inputs_no_clk_rst

set_output_delay 2.0 -max -clock main_clk [all_outputs]
set_load [expr [load_of $lib_name/AND2X4/A] * 20] [all_outputs]

set pad_cells [get_cells -hierarchical -filter "ref_name =~ PI* || ref_name =~ PO*"]
if {[sizeof_collection $pad_cells] > 0} { set_dont_touch $pad_cells true }
set_dont_touch [get_cells i_rst] true
set_dont_touch [get_cells i_clk] true

compile_ultra

redirect -file ./rpt/rpt_constraints_slow.rpt { report_constraint -all_violators }
redirect -file ./rpt/rpt_timing_slow.rpt      { report_timing }
redirect -file ./rpt/rpt_area_slow.rpt        { report_area }
redirect -file ./rpt/rpt_power_slow.rpt       { report_power }
redirect -file ./rpt/rpt_qor_slow.rpt         { report_qor }

write -hierarchy -format ddc     -output ./mapped/cpu_pad_mapped_slow.ddc
write -hierarchy -format verilog -output ./mapped/cpu_pad_netlist_slow.v
write_sdc ./mapped/cpu_pad_slow.sdc
write_sdf ./mapped/cpu_pad_slow.sdf

puts "\[INFO\] Relaxed synthesis complete."