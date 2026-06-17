#===========================================================================
# route.tcl — ICC2 Routing + Parasitic Extraction
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Routing: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from cts -to route
open_mw_cel route

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 1. Pre-route checks
#---------------------------------------------------------------------
check_physical_design -stage pre_route_opt
all_ideal_nets
all_high_fanout -nets -threshold 20

#---------------------------------------------------------------------
# 2. PG connections
#---------------------------------------------------------------------
derive_pg_connection -power_net VDD -power_pin VDD \
                     -ground_net VSS -ground_pin VSS -tie

#---------------------------------------------------------------------
# 3. Route clock nets first
#---------------------------------------------------------------------
route_zrt_group -all_clock_nets -reuse_existing_global_route true

#---------------------------------------------------------------------
# 4. Signal routing (initial route only, skip lengthy timing opt)
#---------------------------------------------------------------------
route_opt -initial_route_only

#---------------------------------------------------------------------
# 5. Basic DRC cleanup
#---------------------------------------------------------------------
verify_zrt_route
route_zrt_detail -incremental true

save_mw_cel -as route

#---------------------------------------------------------------------
# 6. Write outputs
#---------------------------------------------------------------------
change_names -hierarchy -rules verilog
write_verilog -no_physical_only_cells \
              -no_unconnected_cells \
              -no_tap_cells \
              ../output/$DESIGN_NAME\_final.v

extract_rc -coupling_cap
write_parasitics -output ../output/$DESIGN_NAME.spef \
                 -format SPEF \
                 -compress \
                 -no_name_mapping

# Write SDF directly from ICC2
write_sdf ../output/$DESIGN_NAME.sdf

puts "\n\[INFO\] Routing complete."
puts "  Netlist: ../output/$DESIGN_NAME\_final.v"
puts "  SPEF:    ../output/$DESIGN_NAME.spef"
puts "  SDF:     ../output/$DESIGN_NAME.sdf"
puts "============================================\n"