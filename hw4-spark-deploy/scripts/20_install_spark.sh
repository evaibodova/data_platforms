#!/bin/bash

source "$(dirname "$0")/variables.sh"

"$JAVA_HOME/bin/java" -version
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls /
as_hadoop "$HADOOP_HOME/bin/yarn" node -list
sudo systemctl is-active --quiet hive-metastore
sudo systemctl is-active --quiet hive-hiveserver2

archive="spark-${SPARK_VERSION}-bin-without-hadoop.tgz"
url="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}"

if ! as_hadoop test -x "$SPARK_HOME/bin/spark-shell"
then
    if as_hadoop test -e "$SPARK_HOME"
    then
        echo "FAIL: incomplete Spark installation at $SPARK_HOME" >&2
        exit 1
    fi

    as_hadoop curl --fail --location --retry 3 \
        "$url/$archive" -o "/home/hadoop/$archive.part"
    as_hadoop curl --fail --location --retry 3 \
        "$url/$archive.sha512" -o "/home/hadoop/$archive.sha512"

    expected=$(as_hadoop cat "/home/hadoop/$archive.sha512" | python3 -c \
        'import re,sys; m=re.search(r"\b[0-9a-fA-F]{128}\b",sys.stdin.read()); sys.exit("Invalid SHA512 file") if not m else print(m[0].lower())')
    actual=$(as_hadoop sha512sum "/home/hadoop/$archive.part" | cut -d ' ' -f 1)

    if [ "$expected" != "$actual" ]
    then
        echo "FAIL: Spark checksum mismatch" >&2
        exit 1
    fi

    as_hadoop mv "/home/hadoop/$archive.part" "/home/hadoop/$archive"
    as_hadoop tar -xzf "/home/hadoop/$archive" -C /home/hadoop
fi

as_spark "$SPARK_HOME/bin/spark-submit" --version
echo "OK: Spark is installed"
