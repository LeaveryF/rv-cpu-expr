#!/bin/bash
#=== run_cts.sh ===
set -e
cd "$(dirname "$0")"
icc_shell -f ../scripts/cts.tcl 2>&1 | tee ../logs/cts.log
echo "=> cts done, log: logs/cts.log"
