#!/bin/bash

source "$(dirname "$0")/variables.sh"

mkdir -p "$PREFECT_HOME"
mkdir -p "$PROJECT_DIR/logs"

cat > "$PROJECT_DIR/prefect.toml" <<EOF
[server]
analytics_enabled = false

[server.ephemeral]
enabled = true
EOF

cd "$PROJECT_DIR"

"$PREFECT_VENV/bin/prefect" config view

echo "OK: Prefect is configured"
