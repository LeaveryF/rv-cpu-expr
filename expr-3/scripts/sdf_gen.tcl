#===========================================================================
# sdf_gen.tcl — PrimeTime SDF Generation from SPEF parasitics
#===========================================================================

set link_library "\
    /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db \
    /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db"

set target_library $link_library

# Read post-layout netlist
read_verilog ../output/cpu_pad_final.v
current_design cpu_pad
link

# Read parasitics (SPEF)
read_parasitics -pin_cap_included ../output/cpu_pad.spef.max.gz

# Check timing
check_timing
report_timing

# Write SDF
write_sdf ../output/cpu_pad_pt.sdf

puts "\[INFO\] SDF written to ../output/cpu_pad_pt.sdf"
