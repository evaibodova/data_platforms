#!/bin/bash

source "$(dirname "$0")/variables.sh"

shopt -s nullglob
files=("$PROJECT_DIR/data/"*.tsv)

if [ "${#files[@]}" -eq 0 ]
then
    echo "FAIL: no TSV files in data/" >&2
    exit 1
fi

for file in "${files[@]}"
do
    dt=$(basename "$file" .tsv)
    if ! [[ "$dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || \
        [ "$(date -d "$dt" +%F)" != "$dt" ]
    then
        echo "FAIL: invalid date filename: $file" >&2
        exit 1
    fi

    if ! awk -F '\t' 'NF!=2 || $1 !~ /^[A-Za-z]+$/ || $2 !~ /^-?[0-9]+$/ || $2+0 < -2147483648 || $2+0 > 2147483647 {bad=1} END {exit (bad || NR==0)}' "$file"
    then
        echo "FAIL: invalid TSV file: $file" >&2
        exit 1
    fi
done

for file in "${files[@]}"
do
    dt=$(basename "$file" .tsv)
    partition="$SPARK_INPUT/dt=$dt"
    as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p "$partition"
    as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -put -f - "$partition/colours.tsv" < "$file"
done

as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls -R "$SPARK_INPUT"
echo "OK: input TSV files are loaded into HDFS"
