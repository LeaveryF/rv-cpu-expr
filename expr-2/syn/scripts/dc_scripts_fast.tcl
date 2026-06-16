#===========================================================================
# dc_scripts_fast.tcl — Synthesis with tighter timing constraint (5ns / 200MHz)
#===========================================================================
#  Use this script to compare the effect of tighter timing constraints.
#  Run after the default script:
#    dc_shell-64> remove_design -designs
#    dc_shell-64> source ./scripts/dc_scripts_fast.tcl
#===========================================================================

puts "============================================"
puts "  MiniRV CPU Logic Synthesis (FAST: 200MHz)"
puts "============================================"

# Read & elaborate (same as default)
set sv_files [glob ./rtl/*.sv]
analyze -format sverilog $sv_files
elaborate cpu_pad
current_design cpu_pad
link
write -hierarchy -format ddc -output ./unmapped/cpu_pad_unmapped_fast.ddc

set lib_name typical_1v2c25

# Tighter clock: 5ns (200MHz)
set CLK_PERIOD     5.0
set CLK_UNCERTAINTY 0.1
set CLK_PORT       clk_pad

create_clock -period $CLK_PERIOD -name main_clk [get_ports $CLK_PORT]
set_clock_uncertainty $CLK_UNCERTAINTY [get_clocks main_clk]

puts "\[INFO\] Clock: $CLK_PORT, period=${CLK_PERIOD}ns, uncertainty=${CLK_UNCERTAINTY}ns"

# Tighter input constraints
set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set all_inputs_no_clk_rst [remove_from_collection $all_inputs_no_clk [get_ports rst_n_pad]]
set_driving_cell -library $lib_name -lib_cell AND2X4 $all_inputs_no_clk_rst
set_input_delay 0.05 -max -clock main_clk $all_inputs_no_clk_rst

# Tighter output constraints
set_output_delay 0.5 -max -clock main_clk [all_outputs]
set_load [expr [load_of $lib_name/AND2X4/A] * 10] [all_outputs]

# Don't touch PADs
set pad_cells [get_cells -hierarchical -filter "ref_name =~ PI* || ref_name =~ PO*"]
if {[sizeof_collection $pad_cells] > 0} { set_dont_touch $pad_cells true }
set_dont_touch [get_cells i_rst] true
set_dont_touch [get_cells i_clk] true

# Compile
compile_ultra

# Reports (with "fast_" prefix)
redirect -file ./rpt/rpt_constraints_fast.rpt { report_constraint -all_violators }
redirect -file ./rpt/rpt_timing_fast.rpt      { report_timing }
redirect -file ./rpt/rpt_timing_max_fast.rpt  { report_timing -delay max -nworst 10 }
redirect -file ./rpt/rpt_area_fast.rpt        { report_area }
redirect -file ./rpt/rpt_power_fast.rpt       { report_power }
redirect -file ./rpt/rpt_cell_fast.rpt        { report_cell [get_cells -hierarchical] }
redirect -file ./rpt/rpt_qor_fast.rpt         { report_qor }

# Outputs (with "fast_" prefix)
write -hierarchy -format ddc     -output ./mapped/cpu_pad_mapped_fast.ddc
write -hierarchy -format verilog -output ./mapped/cpu_pad_netlist_fast.v
write_sdc ./mapped/cpu_pad_fast.sdc
write_sdf ./mapped/cpu_pad_fast.sdf

puts "\[INFO\] Fast synthesis complete. Compare rpt/*.rpt vs rpt/*_fast.rpt"