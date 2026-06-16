#!/bin/bash
#=== run_place.sh ===
set -e
cd "$(dirname "$0")"
icc_shell -f ../scripts/place.tcl 2>&1 | tee ../logs/place.log
echo "=> place done, log: logs/place.log"
