#!/bin/bash

source "$(dirname "$0")/variables.sh"

sudo systemctl is-active --quiet hive-metastore
sudo systemctl is-active --quiet hive-hiveserver2

result=$(beeline --silent=true --showHeader=false --outputformat=tsv2 -e \
    'SELECT dt, colour, row_count, total_number, max_number FROM test.colours_summary;')

expected=$(printf '%s\n' \
    $'2024-08-09\tblue\t1\t7\t7' \
    $'2024-08-09\tgreen\t1\t3\t3' \
    $'2024-08-09\tred\t2\t17\t12' \
    $'2024-08-10\tblue\t2\t19\t15' \
    $'2024-08-10\tgreen\t1\t8\t8' \
    $'2024-08-10\tred\t1\t9\t9' | LC_ALL=C sort)
actual=$(printf '%s\n' "$result" | LC_ALL=C sort)

printf '%s\n' "$actual"

if [ "$actual" != "$expected" ]
then
    echo "FAIL: Hive result differs from the expected six rows" >&2
    exit 1
fi

partitions=$(beeline --silent=true --showHeader=false --outputformat=tsv2 \
    -e 'SHOW PARTITIONS test.colours_summary;' | LC_ALL=C sort)
expected_partitions=$(printf '%s\n' 'dt=2024-08-09' 'dt=2024-08-10')

if [ "$partitions" != "$expected_partitions" ]
then
    echo "FAIL: expected two Hive partitions" >&2
    exit 1
fi

as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls -R "$SPARK_OUTPUT"
echo "OK: Hive reads Spark results; both partitions and all six rows are correct"
