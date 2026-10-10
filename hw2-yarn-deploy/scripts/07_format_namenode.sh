#!/bin/bash

source "$(dirname "$0")/variables.sh"

HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

sudo -u hadoop ssh "hadoop@$NAME_NODE" "
	cd \"$HADOOP_HOME\"
	bin/hdfs namenode -format
"