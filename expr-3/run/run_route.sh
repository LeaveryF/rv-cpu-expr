#!/bin/bash
#=== run_route.sh ===
set -e
cd "$(dirname "$0")"
icc_shell -f ../scripts/route.tcl 2>&1 | tee ../logs/route.log
echo "=> route done, log: logs/route.log"
