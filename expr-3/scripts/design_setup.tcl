#===========================================================================
# design_setup.tcl — ICC2 Data Preparation
#   Creates MW library, reads netlist & constraints, applies TLU+
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Data Setup: $DESIGN_NAME"
puts "============================================"

#---------------------------------------------------------------------
# 1. Create Milkyway library
#---------------------------------------------------------------------
if {[file exists $DESIGN_NAME.mw]} {
    puts "\[WARN\] $DESIGN_NAME.mw already exists, removing ..."
    exec rm -rf $DESIGN_NAME.mw
}

create_mw_lib $DESIGN_NAME.mw \
    -open \
    -technology $TECH_FILE \
    -mw_reference_library $MW_REFERENCE_LIB_DIRS

puts "\[INFO\] MW library created."

#---------------------------------------------------------------------
# 2. Read netlist and set top design
#---------------------------------------------------------------------
read_verilog -top $DESIGN_NAME $ICC_INPUTS_PATH/$ICC_IN_VERILOG_NETLIST_FILE

current_design $DESIGN_NAME
uniquify
save_mw_cel -as $DESIGN_NAME

puts "\[INFO\] Netlist read and uniquified."

#---------------------------------------------------------------------
# 3. TLU+ parasitics model
#---------------------------------------------------------------------
set_tlu_plus_files \
    -max_tluplus $TLUPLUS_MAX_FILE \
    -min_tluplus $TLUPLUS_MIN_FILE \
    -tech2itf_map $TECH2ITF_MAP_FILE

puts "\[INFO\] TLU+ files set."

#---------------------------------------------------------------------
# 4. Power/Ground connections
#---------------------------------------------------------------------
derive_pg_connection -create_net
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -create_ports top -tie

check_mv_design

puts "\[INFO\] PG connections established."

#---------------------------------------------------------------------
# 5. Read timing constraints
#---------------------------------------------------------------------
read_sdc $ICC_INPUTS_PATH/$DESIGN_NAME.sdc
check_timing
report_timing_requirements
report_disable_timing

puts "\[INFO\] SDC constraints loaded."

#---------------------------------------------------------------------
# 6. Clock report
#---------------------------------------------------------------------
report_clock
report_clock -skew

#---------------------------------------------------------------------
# 7. Initial timing check (zero wire load)
#---------------------------------------------------------------------
source ../scripts/common_optimization_settings_icc.tcl
set_zero_interconnect_delay_mode true
report_constraint -all
report_timing
set_zero_interconnect_delay_mode false

# Remove ideal network on clock/reset after initial check
remove_ideal_network [get_ports "clk_pad rst_n_pad"]

#---------------------------------------------------------------------
# 8. Save initial cell
#---------------------------------------------------------------------
save_mw_cel -as data_setup

puts "\n\[INFO\] Data setup complete. Cell 'data_setup' saved."
puts "============================================\n"
