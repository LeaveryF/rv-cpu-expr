#!/bin/bash
# Run design_setup in ICC2
if [ -f ../logs/design_setup.log ]; then
    rm ../logs/design_setup.log
fi
icc_shell -f ../scripts/design_setup.tcl 2>&1 | tee -i ../logs/design_setup.log
