#===========================================================================
# dc_setup.tcl — DC-specific configuration
#===========================================================================

# Suppress common non-critical messages
suppress_message UID-401
suppress_message LNK-041
suppress_message OPT-1206

# Set default operating conditions
# (typical_1v2c25 library: nominal 1.2V, 25C)

# Enable multi-core processing
set_host_options -max_cores 4

# Don't let DC overwrite existing .ddc files
set_app_var ddc_force_resource_sharing_on_read false

puts "\[INFO\] dc_setup.tcl loaded."