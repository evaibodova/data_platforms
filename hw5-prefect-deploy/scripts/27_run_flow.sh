#!/bin/bash

source "$(dirname "$0")/variables.sh"

if [ ! -f "$PREFECT_FLOW_FILE" ]
then
    echo "FAIL: flow file not found: $PREFECT_FLOW_FILE" >&2
    exit 1
fi

cd "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/logs"
rm -f "$PREFECT_RUN_FILE"

export PREFECT_RUN_FILE

"$PREFECT_VENV/bin/python" "$PREFECT_FLOW_FILE" \
    2>&1 | tee "$PROJECT_DIR/logs/prefect-flow.log"

echo "OK: Prefect flow execution completed"