#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

for step in 20_install_spark.sh 21_setup_spark_env.sh 22_load_spark_data.sh 23_run_spark.sh 24_check_spark.sh
do
    echo "Running scripts/$step"
    bash "scripts/$step"
done
