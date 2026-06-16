#===========================================================================
# common_placement_settings_icc.tcl — ICC2 placement settings
#===========================================================================

# Enable timing-driven placement
set_app_var placer_enable_enhanced_router true

# Congestion effort
set_app_var placer_congestion_effort high

puts "\[INFO\] common_placement_settings_icc.tcl loaded."
