#!/bin/bash

source "$(dirname "$0")/variables.sh"

if [ ! -f "$PREFECT_RUN_FILE" ]
then
    echo "FAIL: flow run result not found: $PREFECT_RUN_FILE" >&2
    exit 1
fi

"$PREFECT_VENV/bin/python" - "$PREFECT_RUN_FILE" <<'PY'
import json
import sys
from pathlib import Path
from uuid import UUID

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

if result.get("state") != "COMPLETED":
    sys.exit(f"FAIL: flow state is {result.get('state')}")

UUID(result["flow_run_id"])

print("Flow run ID:", result["flow_run_id"])
print("Flow state:", result["state"])
PY

bash "$PROJECT_DIR/scripts/24_check_spark.sh"

echo "OK: Prefect flow completed successfully and the result table is correct"