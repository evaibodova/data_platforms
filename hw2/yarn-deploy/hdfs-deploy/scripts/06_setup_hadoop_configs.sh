#!/bin/bash

source "$(dirname "$0")/variables.sh"

HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

sudo -u hadoop tee "$HADOOP_HOME/etc/hadoop/core-site.xml" > /dev/null << EOF
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAME_NODE}:9000</value>
    </property>
</configuration>
EOF

sudo -u hadoop tee "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" > /dev/null << EOF
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
  <property>
    <name>dfs.namenode.secondary.http-address</name>
    <value>${SECONDARY_NAME_NODE}:9868</value>
  </property>
  <property>
    <name>dfs.namenode.rpc-bind-host</name>
    <value>0.0.0.0</value>
  </property>
</configuration>
EOF

{
    echo "# localhost"
    printf "%s\n" "${DATA_NODES[@]}"
} | sudo -u hadoop tee "$HADOOP_HOME/etc/hadoop/workers" > /dev/null

for node in "${DATA_NODES[@]}"
do
  sudo -u hadoop scp "$HADOOP_HOME/etc/hadoop/core-site.xml" "$node:$HADOOP_HOME/etc/hadoop/core-site.xml"
  sudo -u hadoop scp "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" "$node:$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
  sudo -u hadoop scp "$HADOOP_HOME/etc/hadoop/workers" "$node:$HADOOP_HOME/etc/hadoop/workers"
done
