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

check_physical_design -stage pre_clock_opt
check_clock_tree

# Remove ideal network on clock before CTS
remove_ideal_network [get_ports clk_pad]

# CTS settings
set_clock_tree_options -target_early_delay 0.9
set_clock_tree_options -target_skew 0.2
report_clock_tree -settings

# Clock tree synthesis
compile_clock_tree
update_clock_latency
report_clock_tree
report_clock_timing -type skew

# Route clock nets
route_zrt_group -all_clock_nets -reuse_existing_global_route true

save_mw_cel -as cts

puts "\n\[INFO\] CTS complete. Cell 'cts' saved."
puts "============================================\n"
