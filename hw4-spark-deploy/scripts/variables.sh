#!/bin/bash

HADOOP_VERSION="3.4.0"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

EDGE_NODE="team-03-en"
NAME_NODE="team-03-nn"
SECONDARY_NAME_NODE="team-03-en"
DATA_NODES=(
    "team-03-nn"
    "team-03-00"
    "team-03-01"
)

ALL_NODES=(
    "team-03-en"
    "team-03-nn"
    "team-03-00"
    "team-03-01"
)



set -euo pipefail
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

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


SPARK_VERSION="3.5.3"
SPARK_HOME="/home/hadoop/spark-${SPARK_VERSION}-bin-without-hadoop"
SPARK_CONF_DIR="$SPARK_HOME/conf"
SPARK_INPUT="hdfs://${NAME_NODE}:9000/user/hadoop/spark-input/colours"
SPARK_OUTPUT="hdfs://${NAME_NODE}:9000/user/hive/warehouse/external/test.db/colours_summary"
SPARK_JOB="/home/hadoop/spark-hw4/colours_transform.scala"

export SPARK_HOME SPARK_CONF_DIR

as_spark()
{
    as_hadoop env \
        SPARK_HOME="$SPARK_HOME" \
        SPARK_CONF_DIR="$SPARK_CONF_DIR" \
        SPARK_DIST_CLASSPATH="$SPARK_HOME/jars/*:$(as_hadoop "$HADOOP_HOME/bin/hadoop" classpath)" \
        "$@"
}
