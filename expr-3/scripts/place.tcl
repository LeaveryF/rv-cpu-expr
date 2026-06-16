#===========================================================================
# place.tcl — ICC2 Placement (legacy flow, avoiding place_opt bug)
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
# 1. Settings
#---------------------------------------------------------------------
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 2. Pre-placement check
#---------------------------------------------------------------------
check_physical_design -stage pre_place_opt

#---------------------------------------------------------------------
# 3. Set ideal network for clock
#---------------------------------------------------------------------
set_ideal_network [all_fanout -flat -clock_tree]

#---------------------------------------------------------------------
# 4. Placement using legacy flow (avoid place_opt tool bug)
#---------------------------------------------------------------------
# Coarse placement
create_fp_placement -congestion -timing -no_hierarchy_gravity

# Legalize
legalize_placement

# Optimization after placement
psynopt -area_recovery -congestion

# Refine placement
refine_placement -congestion_effort high

# Final optimization
psynopt -area_recovery -congestion

#---------------------------------------------------------------------
# 5. Quality check
#---------------------------------------------------------------------
create_qor_snapshot -name placed
query_qor_snapshot -name placed

save_mw_cel -as placed

puts "\n\[INFO\] Placement complete. Cell 'placed' saved."
puts "============================================\n"
