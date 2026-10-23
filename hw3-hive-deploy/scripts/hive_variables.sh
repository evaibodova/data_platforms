#!/bin/bash
# shellcheck disable=SC2034
set -euo pipefail
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Используем топологию и версию Hadoop из ДЗ 2.
source "$PROJECT_DIR/scripts/variables.sh"
HIVE_VERSION="4.0.0-alpha-2"
HIVE_HOME="/home/hadoop/apache-hive-${HIVE_VERSION}-bin"
HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"
HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
HIVE_CONF_DIR="$HIVE_HOME/conf"
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)"
JDBC_VERSION="8.0.33"
JDBC_URL="jdbc:hive2://${EDGE_NODE}:10000/default"

export JAVA_HOME HADOOP_HOME HADOOP_CONF_DIR HIVE_HOME HIVE_CONF_DIR
if [ "$(hostname)" != "$EDGE_NODE" ]; then
    echo "Error: script should be run from the edge node ($EDGE_NODE)" >&2
    exit 1
fi

as_hadoop() {
    sudo -u hadoop -H env JAVA_HOME="$JAVA_HOME" HADOOP_HOME="$HADOOP_HOME" \
        HADOOP_CONF_DIR="$HADOOP_CONF_DIR" HIVE_HOME="$HIVE_HOME" \
        HIVE_CONF_DIR="$HIVE_CONF_DIR" "$@"
}

beeline() {
    as_hadoop "$HIVE_HOME/bin/beeline" -u "$JDBC_URL" -n hadoop \
        --force=false "$@"
}
