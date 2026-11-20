#!/bin/bash

source "$(dirname "$0")/variables.sh"

for file in \
    "$PROJECT_DIR/spark/colours_transform.scala" \
    "$PROJECT_DIR/sql/02_create_spark_table.sql"
do
    if [ ! -f "$file" ]
    then
        echo "FAIL: missing project file: $file" >&2
        exit 1
    fi
done

mkdir -p "$PROJECT_DIR/logs"

as_hadoop tee "$SPARK_JOB" > /dev/null < "$PROJECT_DIR/spark/colours_transform.scala"

as_spark "$SPARK_HOME/bin/spark-shell" \
    --master yarn \
    --deploy-mode client \
    --name hw4-colours \
    --conf "spark.hw4.input=$SPARK_INPUT" \
    --conf "spark.hw4.output=$SPARK_OUTPUT" \
    -i "$SPARK_JOB" < /dev/null 2>&1 | tee "$PROJECT_DIR/logs/spark-job.log"

grep -Fq 'OK: Spark transformed HDFS data and saved partitioned Parquet' \
    "$PROJECT_DIR/logs/spark-job.log"

beeline --hivevar "spark_output=$SPARK_OUTPUT" \
    -f /dev/stdin < "$PROJECT_DIR/sql/02_create_spark_table.sql"

echo "OK: Spark result is registered as test.colours_summary"
