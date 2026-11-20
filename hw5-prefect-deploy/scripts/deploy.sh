#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

for step in 25_install_prefect.sh 26_setup_prefect.sh 27_run_flow.sh 28_check_flow.sh
do
    echo "Running scripts/$step"
    bash "scripts/$step"
done
