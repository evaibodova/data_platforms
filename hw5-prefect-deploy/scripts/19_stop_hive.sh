#!/bin/bash
source "$(dirname "$0")/variables.sh"
sudo systemctl stop hive-hiveserver2 hive-metastore
