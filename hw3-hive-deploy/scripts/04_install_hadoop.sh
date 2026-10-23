#!/bin/bash

source "$(dirname "$0")/variables.sh"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

if ! sudo -u hadoop test -d /home/hadoop/hadoop-"$HADOOP_VERSION"
then
    if ! sudo -u hadoop test -f /home/hadoop/hadoop-"$HADOOP_VERSION".tar.gz
    then
        sudo -u hadoop wget "$HADOOP_URL" \
            -O /home/hadoop/hadoop-"$HADOOP_VERSION".tar.gz
    fi

    sudo -u hadoop tar -xzvf \
        /home/hadoop/hadoop-"$HADOOP_VERSION".tar.gz \
        -C /home/hadoop/
fi

for node in "${DATA_NODES[@]}"
do
    if sudo -u hadoop ssh "hadoop@$node" \
        "test -d /home/hadoop/hadoop-${HADOOP_VERSION}"
    then
        echo "Hadoop is already installed on $node"
        continue
    fi

    if ! sudo -u hadoop ssh "hadoop@$node" \
        "test -f /home/hadoop/hadoop-${HADOOP_VERSION}.tar.gz"
    then
        sudo -u hadoop scp \
            /home/hadoop/hadoop-"$HADOOP_VERSION".tar.gz \
            "hadoop@$node:/home/hadoop/"
    fi

    sudo -u hadoop ssh "hadoop@$node" "
        tar -xzvf /home/hadoop/hadoop-${HADOOP_VERSION}.tar.gz \
            -C /home/hadoop/
    "
done