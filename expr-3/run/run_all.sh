#!/bin/bash
#=== run_all.sh — Full ICC2 physical design flow ===
set -e
cd "$(dirname "$0")"
mkdir -p ../logs ../output

echo "=========================================="
echo " Stage 1/5: Data Setup"
echo "=========================================="
./run_design_setup.sh

echo "=========================================="
echo " Stage 2/5: Floorplan"
echo "=========================================="
./run_floorplan.sh

echo "=========================================="
echo " Stage 3/5: Placement"
echo "=========================================="
./run_place.sh

echo "=========================================="
echo " Stage 4/5: Clock Tree Synthesis"
echo "=========================================="
./run_cts.sh

echo "=========================================="
echo " Stage 5/5: Routing + Extraction"
echo "=========================================="
./run_route.sh

echo ""
echo "=========================================="
echo " All ICC2 stages complete!"
echo " Logs: ../logs/*.log"
echo " Output: ../output/*"
echo "=========================================="
