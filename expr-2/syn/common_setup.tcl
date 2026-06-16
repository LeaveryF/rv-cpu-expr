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

# ===========================================================================
# DC application variables — these are the ones DC actually reads
# ===========================================================================
set search_path [concat ./rtl ./scripts ./unmapped $search_path]
set target_library $TARGET_LIBRARY_FILES
set link_library "* $TARGET_LIBRARY_FILES"
set symbol_library $SYMBOL_LIBRARY_FILES

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