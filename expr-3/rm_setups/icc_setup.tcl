#===========================================================================
# icc_setup.tcl — ICC2 technology & library setup for SMIC 0.13µm 8-layer
#===========================================================================

# --- Technology file ---
set TECH_FILE "/home/eda/lib/smic/aci/sc-x/apollo/tf/smic13g_8lm.tf"

# --- Milkyway reference libraries ---
# Standard cell + IO PAD libraries
set MW_REFERENCE_LIB_DIRS "\
    /home/eda/lib/smic/aci/sc-x/apollo/smic13g \
    /home/eda/lib/smic/SP013D3_V1p4/apollo/SP013D3_V1p2_8MT"

# --- TLUPLUS files (RC parasitics models, p1mt8 = 8 metal layers) ---
set TLUPLUS_BASE "/home/eda/lib/smic/SmicSPM4PR8R_starRCXT013_mixrf_p1mtx_1233_V1/SmicSPM4PR8R_starRCXT013_mixrf_p1mtx_1233_V1.6"
set MAP_BASE $TLUPLUS_BASE

set TLUPLUS_MAX_FILE   "$TLUPLUS_BASE/ITF/TM9k_MIM1f/TLUPLUS/SmicSPM4PR8R_starRCXT013_log_mixRF_p1mt8_cell_max_1233_9k_1f.tluplus"
set TLUPLUS_MIN_FILE   "$TLUPLUS_BASE/ITF/TM9k_MIM1f/TLUPLUS/SmicSPM4PR8R_starRCXT013_log_mixRF_p1mt8_cell_min_1233_9k_1f.tluplus"
set TLUPLUS_TYP_FILE   "$TLUPLUS_BASE/ITF/TM9k_MIM1f/TLUPLUS/SmicSPM4PR8R_starRCXT013_log_mixRF_p1mt8_cell_typ_1233_9k_1f.tluplus"
set TECH2ITF_MAP_FILE  "$MAP_BASE/mapping/TM9k_MIM1f/SmicSPM4PR8R_013_log_mixRF_p1mt8_cell_typ_1233_9k_1f.map"

# --- Design configuration ---
set DESIGN_NAME       "cpu_pad"
set ICC_IN_VERILOG_NETLIST_FILE "cpu_pad_netlist.v"
set ICC_INPUTS_PATH   "../design_data"
set ICC_INIT_DESIGN_INPUT "VERILOG"

# --- Library search path for .db files ---
set ADDITIONAL_LINK_LIB_FILES "\
    /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db \
    /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db"

# --- Power nets ---
set MW_POWER_NET   "VDD"
set MW_GROUND_NET  "VSS"

puts "\[INFO\] icc_setup.tcl loaded successfully."
puts "\[INFO\]   TECH_FILE  = $TECH_FILE"
puts "\[INFO\]   MW_REFS    = $MW_REFERENCE_LIB_DIRS"
puts "\[INFO\]   TLU+ (typ) = $TLUPLUS_TYP_FILE"
