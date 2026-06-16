#!/bin/bash
#=== run_floorplan.sh ===
set -e
cd "$(dirname "$0")"
icc_shell -f ../scripts/floorplan.tcl 2>&1 | tee ../logs/floorplan.log
echo "=> floorplan done, log: logs/floorplan.log"
