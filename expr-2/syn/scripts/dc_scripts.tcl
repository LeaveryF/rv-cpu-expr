#===========================================================================
# dc_scripts.tcl — Synthesis script for MiniRV CPU
#===========================================================================

# Ensure output directories exist
exec mkdir -p ./mapped ./rpt ./unmapped

puts "============================================"
puts "  MiniRV CPU Logic Synthesis"
puts "============================================"

#---------------------------------------------------------------------
# 1. Read RTL design
#---------------------------------------------------------------------
set sv_files [glob ./rtl/*.sv]
puts "\[INFO\] Reading SystemVerilog files:"
foreach f $sv_files {
    puts "    $f"
}
analyze -format sverilog $sv_files

puts "\[INFO\] Elaborating top module: cpu_pad"
elaborate cpu_pad

# Initial check
current_design cpu_pad
link

# Write unmapped design
write -hierarchy -format ddc -output ./unmapped/cpu_pad_unmapped.ddc

# Report design hierarchy
puts "\n\[INFO\] Design hierarchy:"
list_designs
puts "\n\[INFO\] Loaded libraries:"
list_libs

#---------------------------------------------------------------------
# 2. Set library name for driving cells / load calculations
#---------------------------------------------------------------------
set lib_name typical_1v2c25

#---------------------------------------------------------------------
# 3. Clock constraints
#---------------------------------------------------------------------
#   Default period: 20ns (50 MHz)
#   Clock port: clk_pad (external pad pin)
set CLK_PERIOD     20.0
set CLK_UNCERTAINTY 0.2
set CLK_PORT       clk_pad

create_clock -period $CLK_PERIOD -name main_clk [get_ports $CLK_PORT]
set_clock_uncertainty $CLK_UNCERTAINTY [get_clocks main_clk]

puts "\[INFO\] Clock: $CLK_PORT, period=${CLK_PERIOD}ns, uncertainty=${CLK_UNCERTAINTY}ns"

#---------------------------------------------------------------------
# 4. Input constraints
#---------------------------------------------------------------------
#   Set driving cell on all inputs except clock & reset
#   (using smallest AND2 cell from the library)
set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set all_inputs_no_clk_rst [remove_from_collection $all_inputs_no_clk [get_ports rst_n_pad]]

set_driving_cell -library $lib_name -lib_cell AND2X4 $all_inputs_no_clk_rst

# Input delay: 0.1ns max (conservative)
set_input_delay 0.1 -max -clock main_clk $all_inputs_no_clk_rst
set_input_delay 0.05 -min -clock main_clk $all_inputs_no_clk_rst

# Reset is typically asynchronous — don't constrain relative to clock
# (timing analysis will check recovery/removal via async checks)

#---------------------------------------------------------------------
# 5. Output constraints
#---------------------------------------------------------------------
#   Output delay: 1.0ns (external path after chip output)
#   Load: 15x AND2X4 input capacitance (typical PCB trace load)
set_output_delay 1.0 -max -clock main_clk [all_outputs]
set_output_delay 0.5 -min -clock main_clk [all_outputs]

set_load [expr [load_of $lib_name/AND2X4/A] * 15] [all_outputs]

#---------------------------------------------------------------------
# 6. Don't touch PAD cells (they are pre-characterized)
#---------------------------------------------------------------------
#   All PAD instances should be preserved
set pad_cells [get_cells -hierarchical -filter "ref_name =~ PI* || ref_name =~ PO*"]
if {[sizeof_collection $pad_cells] > 0} {
    set_dont_touch $pad_cells true
    puts "\[INFO\] Marked [sizeof_collection $pad_cells] PAD cells as dont_touch"
}

# For the reference-style per-instance approach (match exactly):
# set_dont_touch [get_cells -hierarchical -filter "full_name =~ *gen_*"]
set_dont_touch [get_cells i_rst] true
set_dont_touch [get_cells i_clk] true

#---------------------------------------------------------------------
# 7. Design rule constraints (optional, for tighter timing)
#---------------------------------------------------------------------
# set_max_area 0       # optimize for minimal area
# set_max_fanout 16 cpu_clk
# set_fix_multiple_port_nets -all -buffer_constants

#---------------------------------------------------------------------
# 8. Compile (logic synthesis)
#---------------------------------------------------------------------
puts "\n\[INFO\] Starting compile_ultra ..."
compile_ultra

puts "\[INFO\] Compile complete."

#---------------------------------------------------------------------
# 9. Generate reports
#---------------------------------------------------------------------
puts "\n\[INFO\] Generating reports ..."

redirect -file ./rpt/rpt_constraints.rpt { report_constraint -all_violators }
redirect -file ./rpt/rpt_timing.rpt      { report_timing }
redirect -file ./rpt/rpt_timing_max.rpt  { report_timing -delay max -nworst 10 }
redirect -file ./rpt/rpt_area.rpt        { report_area }
redirect -file ./rpt/rpt_power.rpt       { report_power }
redirect -file ./rpt/rpt_cell.rpt        { report_cell [get_cells -hierarchical] }
redirect -file ./rpt/rpt_resource.rpt    { report_resources }
redirect -file ./rpt/rpt_qor.rpt         { report_qor }

puts "\[INFO\] Reports saved to ./rpt/"

#---------------------------------------------------------------------
# 10. Write outputs
#---------------------------------------------------------------------
puts "\n\[INFO\] Writing output files ..."

# Design database
write -hierarchy -format ddc -output ./mapped/cpu_pad_mapped.ddc

# Gate-level netlist (Verilog)
write -hierarchy -format verilog -output ./mapped/cpu_pad_netlist.v

# SDC constraints (for place & route)
write_sdc ./mapped/cpu_pad.sdc

# SDF (Standard Delay Format) for post-synthesis back-annotation
write_sdf ./mapped/cpu_pad.sdf

puts "\[INFO\] Outputs saved to ./mapped/"
puts "\n============================================"
puts "  Synthesis Complete!"
puts "  Check ./rpt/ for reports"
puts "  Check ./mapped/ for netlist/SDF/SDC"
puts "============================================"