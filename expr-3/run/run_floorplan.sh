#!/bin/bash
# Run floorplan in ICC2
if [ -f ../logs/floorplan.log ]; then
    rm ../logs/floorplan.log
fi
icc_shell -f ../scripts/floorplan.tcl 2>&1 | tee -i ../logs/floorplan.log
