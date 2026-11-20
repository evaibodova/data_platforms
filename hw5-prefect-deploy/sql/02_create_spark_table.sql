CREATE DATABASE IF NOT EXISTS test;

CREATE EXTERNAL TABLE IF NOT EXISTS test.colours_summary (
    colour STRING,
    row_count BIGINT,
    total_number BIGINT,
    max_number INT
)
PARTITIONED BY (dt STRING)
STORED AS PARQUET
LOCATION '${hivevar:spark_output}';

MSCK REPAIR TABLE test.colours_summary SYNC PARTITIONS;
SHOW PARTITIONS test.colours_summary;
SHOW CREATE TABLE test.colours_summary;
