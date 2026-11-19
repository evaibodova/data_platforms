#!/bin/bash

source "$(dirname "$0")/variables.sh"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

if ! command -v java >/dev/null 2>&1
then
  sudo apt update
  sudo apt install -y openjdk-11-jdk-headless
else
  echo "Java is already installed"
fi

for node in "${DATA_NODES[@]}"
do
  echo "===== $node ====="
  ssh "$node" '
    if ! command -v java >/dev/null 2>&1
    then
      sudo apt update
      sudo apt install -y openjdk-11-jdk-headless
    else
      echo "Java is already installed"
    fi
  '
done