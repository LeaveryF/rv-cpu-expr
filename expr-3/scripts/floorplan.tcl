#===========================================================================
# floorplan.tcl — ICC2 Floorplanning
#   Pad placement, core creation, power ring/mesh, rail routing
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Floorplan: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from data_setup -to floorplan
open_mw_cel floorplan

#---------------------------------------------------------------------
# 1. Create corner and power/ground pad cells
#---------------------------------------------------------------------
# Corner cells (physical only, for pad ring continuity)
create_cell {cornerll cornerlr cornerul cornerur} PCORNER

# Core power/ground pads (left/right sides)
create_cell {vss1left vss1right} PVSS1
create_cell {vdd1left vdd1right} PVDD1

# I/O power/ground pads (top/bottom sides)
create_cell {vss2top vss2bottom} PVSS2
create_cell {vdd2top vdd2bottom} PVDD2

puts "\[INFO\] Corner and PG pad cells created."

#---------------------------------------------------------------------
# 2. Create floorplan: square aspect ratio, 70% utilization
#---------------------------------------------------------------------
create_floorplan \
    -control_type aspect_ratio \
    -core_aspect_ratio 1 \
    -core_utilization 0.7 \
    -left_io2core 30 \
    -bottom_io2core 30 \
    -right_io2core 30 \
    -top_io2core 30 \
    -start_first_row

puts "\[INFO\] Floorplan created."

#---------------------------------------------------------------------
# 3. Insert pad fillers
#---------------------------------------------------------------------
insert_pad_filler -cell "PFILL001 PFILL01 PFILL1 PFILL10 PFILL2 PFILL20 PFILL5 PFILL50"

puts "\[INFO\] Pad fillers inserted."

#---------------------------------------------------------------------
# 4. Routing layer restrictions
#---------------------------------------------------------------------
set_ignored_layers -max_routing_layer METAL6
report_ignored_layers

#---------------------------------------------------------------------
# 5. Power network: ring + mesh
#---------------------------------------------------------------------
save_mw_cel -as floorplan_prepns

# Power ring
create_power_plan_regions core -core
set_power_ring_strategy core -core -nets {VDD VSS} \
    -template ../scripts/basic_ring.tpl:basic_ring

remove_power_plan_strategy -all
set_power_plan_strategy s_basic_no_va -nets {VDD VSS} -core \
    -extension {{{nets:VDD}{stop:outermost_ring}} {{nets:VSS}{stop:outermost_ring}}} \
    -template ../scripts/pg_mesh.tpl:pg_mesh_top

compile_power_plan -ring
compile_power_plan

puts "\[INFO\] Power ring and mesh compiled."

#---------------------------------------------------------------------
# 6. PG connections (after ring/mesh creation)
#---------------------------------------------------------------------
derive_pg_connection -create_net
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -tie

save_mw_cel -as floorplanafterpn

#---------------------------------------------------------------------
# 7. Route standard cell rails (METAL3-METAL8)
#---------------------------------------------------------------------
set_preroute_drc_strategy -min_layer METAL3 -max_layer METAL8
preroute_standard_cells -nets "VDD VSS" -remove_floating_pieces -do_not_route_over_macros

#---------------------------------------------------------------------
# 8. Initial placement + global route for congestion check
#---------------------------------------------------------------------
create_fp_placement -congestion -timing -no_hierarchy_gravity
route_zrt_global -congestion_map_only true -exploration true
preroute_instances

save_mw_cel -as floorplaned

puts "\n\[INFO\] Floorplan complete. Cell 'floorplaned' saved."
puts "============================================\n"
