#!/bin/bash

source "$(dirname "$0")/variables.sh"

HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"
HDFS="$HADOOP_HOME/bin/hdfs"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

failed=0

echo "===== CHECKING DATANODES ====="

report=$(sudo -u hadoop ssh "hadoop@$NAME_NODE" \
    "$HDFS dfsadmin -report")

live_nodes=$(echo "$report" | grep -oP 'Live datanodes \(\K[0-9]+')

if [ "$live_nodes" -eq 3 ]
then
    echo "OK: 3 live DataNodes"
else
    echo "FAIL: expected 3 DataNodes, got $live_nodes"
    failed=1
fi


echo
echo "===== CHECKING NAMENODE ====="

if sudo -u hadoop ssh "hadoop@$NAME_NODE" \
    "jps | grep -q NameNode"
then
    echo "OK: NameNode is running"
else
    echo "FAIL: NameNode is not running"
    failed=1
fi


echo
echo "===== CHECKING DATANODE PROCESSES ====="

for node in "${DATA_NODES[@]}"
do
    if sudo -u hadoop ssh "hadoop@$node" \
        "jps | grep -q DataNode"
    then
        echo "OK: DataNode is running on $node"
    else
        echo "FAIL: DataNode is not running on $node"
        failed=1
    fi
done


echo
echo "===== CHECKING SECONDARY NAMENODE ====="

if sudo -u hadoop -H jps | grep -q SecondaryNameNode
then
    echo "OK: SecondaryNameNode is running"
else
    echo "FAIL: SecondaryNameNode is not running"
    failed=1
fi


echo
echo "===== HDFS WRITE/READ TEST ====="

TEST_FILE="/tmp/hdfs_test_$$.txt"
TEST_DIR="/cluster_check"
TEST_TEXT="hello hdfs"

echo "$TEST_TEXT" | sudo -u hadoop tee "$TEST_FILE" > /dev/null

sudo -u hadoop "$HDFS" dfs -mkdir -p "$TEST_DIR"

sudo -u hadoop "$HDFS" dfs -put -f \
    "$TEST_FILE" "$TEST_DIR/test.txt"

result=$(sudo -u hadoop "$HDFS" dfs -cat "$TEST_DIR/test.txt")

if [ "$result" = "$TEST_TEXT" ]
then
    echo "OK: HDFS write/read works"
else
    echo "FAIL: HDFS write/read test failed"
    failed=1
fi


echo
echo "===== HDFS FSCK ====="

if sudo -u hadoop "$HDFS" fsck "$TEST_DIR/test.txt" \
    -files -blocks -locations | grep -q "HEALTHY"
then
    echo "OK: HDFS filesystem is HEALTHY"
else
    echo "FAIL: HDFS fsck failed"
    failed=1
fi


sudo -u hadoop rm -f "$TEST_FILE"
sudo -u hadoop "$HDFS" dfs -rm -r -f "$TEST_DIR" > /dev/null


echo "===== Checking cluster logs ====="

for node in "${DATA_NODES[@]}"
do
    echo "Checking logs on $node..."

    if sudo -u hadoop ssh "hadoop@$node" \
        "tail -n 300 $HADOOP_HOME/logs/*.log 2>/dev/null | grep -E '\b(ERROR|FATAL)\b'"
    then
        echo "FAIL: critical errors found in logs on $node"
        failed=1
    else
        echo "OK: no critical errors in recent logs on $node"
    fi
done

echo "Checking logs on $EDGE_NODE..."

if sudo -u hadoop bash -c \
    "tail -n 300 $HADOOP_HOME/logs/*.log 2>/dev/null | grep -E '\b(ERROR|FATAL)\b'"
then
    echo "FAIL: critical errors found in logs on $EDGE_NODE"
    failed=1
else
    echo "OK: no critical errors in recent logs on $EDGE_NODE"
fi


echo
echo "===== RESULT ====="

if [ "$failed" -eq 0 ]
then
    echo "OK: cluster is healthy"
    exit 0
else
    echo "FAIL: cluster has errors"
    exit 1
fi
