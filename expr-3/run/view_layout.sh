#!/bin/bash
#=== view_layout.sh — Open ICC2 GUI to view layout at any stage ===
# Usage: ./view_layout.sh <stage>
#   stages: data_setup | floorplaned | floorplan_prepns | floorplanafterpn |
#           placed | cts | route
#   e.g.: ./view_layout.sh route
#===
set -e
cd "$(dirname "$0")"

STAGE="${1:-route}"

MW_DIR="$(cd "$(dirname "$0")" && pwd)"
MW_LIB="${MW_DIR}/cpu_pad.mw"

if [ ! -d "$MW_LIB" ]; then
    echo "ERROR: MW library not found at $MW_LIB"
    echo "Please run the flow first: cd $(dirname "$0") && ./run_all.sh"
    exit 1
fi

cat > /tmp/_icc_view_${STAGE}.tcl << EOF
source ${MW_DIR}/../rm_setups/lcrm_setup.tcl
source -echo ${MW_DIR}/../rm_setups/icc_setup.tcl
open_mw_lib ${MW_LIB}
open_mw_cel ${STAGE}
puts "\[INFO\] Opened cell: ${STAGE}"
puts "\[INFO\] Use View > Layout Browser to browse the layout"
EOF

echo "Opening ICC2 GUI for stage: ${STAGE}"
echo "MW library: ${MW_LIB}"
icc_shell -gui -f /tmp/_icc_view_${STAGE}.tcl