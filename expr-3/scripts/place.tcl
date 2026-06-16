#===========================================================================
# place.tcl — ICC2 Placement (basic, no timing opt — CTS/route handle that)
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

# Set clock as ideal net (CTS will handle real clock later)
set_ideal_network [all_fanout -flat -clock_tree]

# Basic placement — no timing optimization yet (CTS first!)
create_fp_placement -congestion -timing -no_hierarchy_gravity
legalize_placement
refine_placement -congestion_effort high

create_qor_snapshot -name placed
query_qor_snapshot -name placed

save_mw_cel -as placed

puts "\n\[INFO\] Placement complete. Cell 'placed' saved."
puts "============================================\n"
