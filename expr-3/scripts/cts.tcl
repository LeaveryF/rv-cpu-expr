#===========================================================================
# cts.tcl — ICC2 Clock Tree Synthesis
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Clock Tree Synthesis: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from placed -to cts
open_mw_cel cts

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 1. Pre-CTS checks
#---------------------------------------------------------------------
check_physical_design -stage pre_clock_opt
check_clock_tree

#---------------------------------------------------------------------
# 2. Remove ideal network, set CTS targets
#---------------------------------------------------------------------
remove_ideal_network [get_ports clk_pad]
remove_clock_uncertainty [all_clocks]

set_clock_tree_options -target_early_delay 0.9
set_clock_tree_options -target_skew 0.2
report_clock_tree -settings

#---------------------------------------------------------------------
# 3. Clock tree synthesis
#---------------------------------------------------------------------
clock_opt -no_clock_route -only_cts
update_clock_latency
report_clock_tree
report_clock_timing -type skew

#---------------------------------------------------------------------
# 4. Post-CTS optimization (hold fixing)
#---------------------------------------------------------------------
set_fix_hold [all_clocks]
clock_opt -no_clock_route -only_psyn
report_clock_tree
report_clock_timing -type skew

#---------------------------------------------------------------------
# 5. Clock tree routing
#---------------------------------------------------------------------
set_fix_hold [all_clocks]
route_zrt_group -all_clock_nets -reuse_existing_global_route true
report_clock_tree
report_clock_timing -type skew

save_mw_cel -as cts

puts "\n\[INFO\] CTS complete. Cell 'cts' saved."
puts "============================================\n"
