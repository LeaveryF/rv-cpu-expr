#!/bin/bash
# Run routing in ICC2
if [ -f ../logs/route.log ]; then
    rm ../logs/route.log
fi
icc_shell -f ../scripts/route.tcl 2>&1 | tee -i ../logs/route.log
