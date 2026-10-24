#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for step in 14_install_hive.sh 15_configure_hive.sh 16_start_hive.sh 17_load_data.sh 18_check_hive.sh; do
    echo "Running scripts/$step"
    bash "scripts/$step"
done
