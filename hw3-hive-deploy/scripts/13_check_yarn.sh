#!/bin/bash

source "$(dirname "$0")/variables.sh"

HADOOP_HOME="/home/hadoop/hadoop-${HADOOP_VERSION}"
YARN="$HADOOP_HOME/bin/yarn"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

failed=0


echo "===== CHECKING RESOURCE MANAGER ====="

if sudo -u hadoop ssh "hadoop@$NAME_NODE" \
    "jps | grep -q ResourceManager"
then
    echo "OK: ResourceManager is running"
else
    echo "FAIL: ResourceManager is not running"
    failed=1
fi


echo
echo "===== CHECKING NODE MANAGERS ====="

for node in "${DATA_NODES[@]}"
do
    if sudo -u hadoop ssh "hadoop@$node" \
        "jps | grep -q NodeManager"
    then
        echo "OK: NodeManager is running on $node"
    else
        echo "FAIL: NodeManager is not running on $node"
        failed=1
    fi
done


echo
echo "===== CHECKING YARN NODES ====="

if node_report=$(sudo -u hadoop "$YARN" node -list 2>/dev/null)
then
    echo "$node_report"

    total_nodes=$(echo "$node_report" | grep -oP 'Total Nodes:\K[0-9]+')
    running_nodes=$(echo "$node_report" | grep -c "RUNNING")

    if [ "$total_nodes" -eq 3 ] && [ "$running_nodes" -eq 3 ]
    then
        echo "OK: 3 NodeManagers are registered and RUNNING"
    else
        echo "FAIL: expected 3 RUNNING NodeManagers"
        failed=1
    fi
else
    echo "FAIL: could not connect to YARN ResourceManager"
    failed=1
fi


echo
echo "===== CHECKING JOB HISTORY SERVER ====="

if sudo -u hadoop ssh "hadoop@$NAME_NODE" \
    "jps | grep -q JobHistoryServer"
then
    echo "OK: JobHistoryServer is running"
else
    echo "FAIL: JobHistoryServer is not running"
    failed=1
fi


echo
echo "===== CHECKING WEB INTERFACES ====="

check_web()
{
    name="$1"
    url="$2"

    status=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$status" = "200" ] || [ "$status" = "302" ]
    then
        echo "OK: $name is available ($status)"
    else
        echo "FAIL: $name is not available (HTTP $status)"
        failed=1
    fi
}

check_web "NameNode UI" \
    "http://$NAME_NODE:9870"

check_web "ResourceManager UI" \
    "http://$NAME_NODE:8088"

check_web "JobHistoryServer UI" \
    "http://$NAME_NODE:19888"

for node in "${DATA_NODES[@]}"
do
    check_web "NodeManager UI on $node" \
        "http://$node:8042"
done

check_web "SecondaryNameNode UI" \
    "http://$EDGE_NODE:9868"


echo
echo "===== RESULT ====="

if [ "$failed" -eq 0 ]
then
    echo "OK: YARN cluster is healthy"
    exit 0
else
    echo "FAIL: YARN cluster has errors"
    exit 1
fi