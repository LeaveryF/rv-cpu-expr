#!/bin/bash
#=== run_design_setup.sh ===
set -e
mkdir -p ../logs ../design_data
cd "$(dirname "$0")"
rm -rf ../cpu_pad.mw

# Ensure design_data has the required input files
if [ ! -f ../design_data/cpu_pad_netlist.v ]; then
    echo "Copying netlist from expr-2..."
    cp ../../expr-2/syn/mapped/cpu_pad_netlist.v ../design_data/
    cp ../../expr-2/syn/mapped/cpu_pad.sdc ../design_data/
fi

icc_shell -f ../scripts/design_setup.tcl 2>&1 | tee ../logs/design_setup.log
echo "=> design_setup done, log: logs/design_setup.log"
