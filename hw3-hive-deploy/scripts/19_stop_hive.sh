#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"
sudo systemctl stop hive-hiveserver2 hive-metastore
# MySQL, HDFS и YARN остаются запущены; данные и схема сохраняются.
