#===========================================================================
# common_optimization_settings_icc.tcl — ICC2 optimization settings
#===========================================================================

# Timing optimization settings
set_app_var timing_enable_multiple_clocks_per_reg true
set_app_var timing_input_port_default_clock true
set_app_var timing_self_loops_no_skew true

# DRC fixing
set_app_var routeopt_drc_over_timing false

# Area recovery during optimization
set_app_var physopt_area_critical_range 0.5

puts "\[INFO\] common_optimization_settings_icc.tcl loaded."
