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

cat > /tmp/_icc_view_${STAGE}.tcl << EOF
source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl
open_mw_lib ${PWD}/../cpu_pad.mw
open_mw_cel ${STAGE}
puts "\[INFO\] Opened cell: ${STAGE}"
puts "\[INFO\] Use View > Layout to see the layout"
puts "\[INFO\] Use Ctrl+D or 'exit' to close"
EOF

echo "Opening ICC2 GUI for stage: ${STAGE}"
echo "Tip: In the GUI, use View > Layout Browser to see the layout"
echo "     Use mousewheel to zoom, middle-click drag to pan"
icc_shell -gui -f /tmp/_icc_view_${STAGE}.tcl