#!/bin/bash
# Run CTS in ICC2
if [ -f ../logs/cts.log ]; then
    rm ../logs/cts.log
fi
icc_shell -f ../scripts/cts.tcl 2>&1 | tee -i ../logs/cts.log
