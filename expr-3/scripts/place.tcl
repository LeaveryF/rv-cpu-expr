#===========================================================================
# place.tcl — ICC2 Placement (basic)
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Placement: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from floorplaned -to place
open_mw_cel place

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

check_physical_design -stage pre_place_opt

set_ideal_network [all_fanout -flat -clock_tree]

# Try coarse placement only (no refine which needs congestion map)
create_fp_placement -timing -no_hierarchy_gravity
legalize_placement

# Report placement results
report_design_physical -utilization

create_qor_snapshot -name placed
query_qor_snapshot -name placed

save_mw_cel -as placed

puts "\n\[INFO\] Placement complete. Cell 'placed' saved."
puts "============================================\n"
