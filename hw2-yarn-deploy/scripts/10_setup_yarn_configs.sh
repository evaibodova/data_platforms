#!/bin/bash

source "$(dirname "$0")/variables.sh"

HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

sudo -u hadoop tee "$HADOOP_HOME/etc/hadoop/mapred-site.xml" > /dev/null << EOF
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF

sudo -u hadoop tee "$HADOOP_HOME/etc/hadoop/yarn-site.xml" > /dev/null << EOF
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>$NAME_NODE</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>$NAME_NODE:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>$NAME_NODE:8031</value>
    </property>
  <property>
    <name>yarn.resourcemanager.bind-host</name>
    <value>0.0.0.0</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>0.0.0.0:8088</value>
  </property>
</configuration>
EOF


for node in "${DATA_NODES[@]}"
do
  sudo -u hadoop scp "$HADOOP_HOME/etc/hadoop/mapred-site.xml" "$node:$HADOOP_HOME/etc/hadoop/mapred-site.xml"
  sudo -u hadoop scp "$HADOOP_HOME/etc/hadoop/yarn-site.xml" "$node:$HADOOP_HOME/etc/hadoop/yarn-site.xml"
done