#===========================================================================
# lcrm_setup.tcl — Library setup for ICC2
#===========================================================================

# Set search path
lappend search_path ../design_data ../scripts ../rm_setups

# ICC2 needs explicit target_library and link_library (unlike DC which reads
# from common_setup.tcl). The MW lib provides physical views, but .db files
# are needed for timing analysis.
set target_library "\
    /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db \
    /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db"

set link_library "* $target_library"

# Suppress common warnings
suppress_message UID-401

puts "\[INFO\] lcrm_setup.tcl loaded."
puts "\[INFO\]   target_library set to 2 .db files"
puts "\[INFO\]   link_library = * + target_library"
