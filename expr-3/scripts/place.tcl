#===========================================================================
# place.tcl — ICC2 Placement
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Placement: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from floorplaned -to place
open_mw_cel place

#---------------------------------------------------------------------
# 1. Optimization and placement settings
#---------------------------------------------------------------------
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 2. Pre-placement checks
#---------------------------------------------------------------------
check_physical_design -stage pre_place_opt

#---------------------------------------------------------------------
# 3. Set ideal network for clock (will be removed in CTS)
#---------------------------------------------------------------------
set_ideal_network [all_fanout -flat -clock_tree]

#---------------------------------------------------------------------
# 4. Placement + optimization
#---------------------------------------------------------------------
place_opt -area_recovery -congestion
psynopt -area_recovery -congestion
refine_placement -congestion_effort high
psynopt -area_recovery -congestion

#---------------------------------------------------------------------
# 5. Quality check
#---------------------------------------------------------------------
create_qor_snapshot -name placed
query_qor_snapshot -name placed

save_mw_cel -as placed

puts "\n\[INFO\] Placement complete. Cell 'placed' saved."
puts "============================================\n"
