#!/bin/bash

source "$(dirname "$0")/variables.sh"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"

echo "export HADOOP_HOME=$HADOOP_HOME" \
    | sudo -u hadoop tee -a /home/hadoop/.profile
echo "export JAVA_HOME=$JAVA_HOME" \
    | sudo -u hadoop tee -a /home/hadoop/.profile
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' \
    | sudo -u hadoop tee -a /home/hadoop/.profile

sudo -u hadoop -H bash -c 'source /home/hadoop/.profile && hadoop version'

echo "export JAVA_HOME=$JAVA_HOME" \
    | sudo -u hadoop tee -a "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

for node in "${DATA_NODES[@]}"
do
    sudo -u hadoop ssh "hadoop@$node" "

        JAVA_HOME=\$(dirname \"\$(dirname \"\$(readlink -f \"\$(command -v java)\")\")\")
        HADOOP_HOME=\"/home/hadoop/hadoop-${HADOOP_VERSION}\"

        echo \"export HADOOP_HOME=\$HADOOP_HOME\" \
            | tee -a /home/hadoop/.profile

        echo \"export JAVA_HOME=\$JAVA_HOME\" \
            | tee -a /home/hadoop/.profile

        echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin' \
            | tee -a /home/hadoop/.profile

    source /home/hadoop/.profile
    hadoop version

    echo \"export JAVA_HOME=\$JAVA_HOME\" \
        | tee -a \"\$HADOOP_HOME/etc/hadoop/hadoop-env.sh\"
    "
done