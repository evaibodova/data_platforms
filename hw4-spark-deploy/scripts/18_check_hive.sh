#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"

for service in mysql hive-metastore hive-hiveserver2
do
    sudo systemctl is-active --quiet "$service" || {
        echo "FAIL: $service is not active" >&2
        exit 1
    }
done

curl --fail --silent --output /dev/null "http://$EDGE_NODE:10002"

mkdir -p "$PROJECT_DIR/logs"
work_dir=$(mktemp -d)
cleanup() {
    exec 7>&- 8>&-
    for pid in ${pid1:-} ${pid2:-}; do kill "$pid" 2>/dev/null || true; done
    rm -rf "$work_dir"
}

trap cleanup EXIT
mkfifo "$work_dir/client1" "$work_dir/client2"
exec 7<>"$work_dir/client1" 8<>"$work_dir/client2"

beeline --silent=true --showHeader=false --outputformat=tsv2 -f /dev/stdin < "$work_dir/client1" 7>&- 8>&- > "$PROJECT_DIR/logs/client1.log" 2>&1 &
pid1=$!
beeline --silent=true --showHeader=false --outputformat=tsv2 -f /dev/stdin < "$work_dir/client2" 7>&- 8>&- > "$PROJECT_DIR/logs/client2.log" 2>&1 &
pid2=$!

printf 'SELECT 1;\n' >&7
printf 'SELECT 1;\n' >&8
ready=false

for attempt in $(seq 1 60)
do
    if grep -qx '1' "$PROJECT_DIR/logs/client1.log" && grep -qx '1' "$PROJECT_DIR/logs/client2.log"
	then
        ready=true; break
    fi
    sleep 2
done

[ "$ready" = true ] || { echo 'FAIL: two clients could not query simultaneously'; exit 1; }
kill -0 "$pid1" "$pid2"

printf '!quit\n' >&7
printf '!quit\n' >&8

wait "$pid1"
wait "$pid2"

pid1=; pid2=

result=$(beeline --silent=true --showHeader=false --outputformat=tsv2 -e \
    "SELECT dt, COUNT(*), MAX(number) FROM test.colours WHERE dt IN ('2024-08-09','2024-08-10') GROUP BY dt ORDER BY dt;")

printf '%s\n' "$result"
printf '%s\n' "$result" | grep -qx $'2024-08-09\t4\t12'
printf '%s\n' "$result" | grep -qx $'2024-08-10\t4\t15'

as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls -R /user/hive/warehouse/external/test.db/colours

echo 'OK: Hive accepts two clients; both partitions contain expected data'
