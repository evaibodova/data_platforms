#!/bin/bash

source "$(dirname "$0")/variables.sh"

python3 -c '
import sys
if sys.version_info < (3, 11):
    sys.exit("FAIL: Python 3.11 or newer is required")
'

sudo apt-get update
sudo apt-get install -y python3-venv

if [ ! -x "$PREFECT_VENV/bin/python" ]
then
    python3 -m venv "$PREFECT_VENV"
fi

"$PREFECT_VENV/bin/python" -m pip install \
    "prefect==$PREFECT_VERSION"

mkdir -p "$PREFECT_HOME"

"$PREFECT_VENV/bin/prefect" version

echo "OK: Prefect is installed"
