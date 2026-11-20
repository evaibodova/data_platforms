#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"

beeline -f /dev/stdin < "$PROJECT_DIR/sql/01_create_table.sql"

input_dir="${1:-$PROJECT_DIR/data}"
shopt -s nullglob
files=("$input_dir"/*.tsv)
[ "${#files[@]}" -gt 0 ] || { echo 'No TSV files found' >&2; exit 1; }

exec 9>"$PROJECT_DIR/.load.lock"
flock -n 9 || { echo 'Another loader is running' >&2; exit 1; }

for file in "${files[@]}"
do
    dt=$(basename "$file" .tsv)
    [[ "$dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [ "$(date -d "$dt" +%F)" = "$dt" ] || {
        echo "Invalid date filename: $file" >&2; exit 1;
    }

    awk -F '\t' 'NF!=2 || $1 !~ /^[A-Za-z]+$/ || $2 !~ /^-?[0-9]+$/ || $2+0 < -2147483648 || $2+0 > 2147483647 {bad=1} END {exit (bad || NR==0)}' "$file" || {
        echo "Invalid TSV: $file" >&2; exit 1;
    }

    stage="/user/hadoop/hive-input/$dt"
    as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p "$stage"
    as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -put -f - "$stage/colours.tsv" < "$file"
    beeline -e "LOAD DATA INPATH '$stage/colours.tsv' OVERWRITE INTO TABLE test.colours PARTITION (dt='$dt');"
	
done
beeline -e 'SHOW PARTITIONS test.colours; SELECT * FROM test.colours LIMIT 10;'
