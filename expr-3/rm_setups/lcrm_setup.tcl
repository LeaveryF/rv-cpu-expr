#===========================================================================
# lcrm_setup.tcl — Library creation / resource manager setup
#===========================================================================

# Set search path to include reference libraries
lappend search_path ../design_data ../scripts ../rm_setups

# Milkyway reference control file
# (empty for this design — no special black boxes beyond what's in MW libs)

puts "\[INFO\] lcrm_setup.tcl loaded."
