#!/bin/bash
# Run placement in ICC2
if [ -f ../logs/place.log ]; then
    rm ../logs/place.log
fi
icc_shell -f ../scripts/place.tcl 2>&1 | tee -i ../logs/place.log
