#===========================================================================
# common_setup.tcl — Library paths and search directories
#===========================================================================

# Search path: directories containing logical libraries and RTL
set ADDITIONAL_SEARCH_PATH \
    "/home/eda/lib/smic/aci/sc-x/synopsys \
     /home/eda/lib/smic/SP013D3_V1p4/syn \
     ./rtl \
     ./scripts \
     ./unmapped"

# Target library files (standard cell + IO pad)
set TARGET_LIBRARY_FILES "\
    /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db \
    /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db"

# Symbol library file (for schematic viewing)
set SYMBOL_LIBRARY_FILES \
    "/home/eda/lib/smic/aci/sc-x/synopsys/smic13g.sdb"

# Additional link libraries (same as target for synthesis)
set LINK_LIBRARY_FILES $TARGET_LIBRARY_FILES

# Optional: Milkyway reference libraries (for physical-aware synthesis)
# set MW_REFERENCE_LIB_DIRS ""
# set MW_DESIGN_LIB ""

# Tcl procedure to print environment info
proc print_setup_info {} {
    puts "============================================"
    puts "  DC Synthesis Environment Setup"
    puts "============================================"
    puts "  TARGET_LIBRARY_FILES:"
    foreach lib $::TARGET_LIBRARY_FILES {
        puts "    $lib"
    }
    puts "  SYMBOL_LIBRARY_FILES: $::SYMBOL_LIBRARY_FILES"
    puts "============================================"
}