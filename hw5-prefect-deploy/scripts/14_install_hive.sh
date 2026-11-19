#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"

for node in "${DATA_NODES[@]}"
do
    ssh -n "$node" '
        set -e
        name=$(hostname -s)

        if grep -Eq "^[[:space:]]*127[.]0[.]1[.]1[[:space:]].*${name}([[:space:].]|$)" /etc/hosts
		then
            sudo -n cp -a /etc/hosts \
                "/etc/hosts.before-hive-$(date +%Y%m%d-%H%M%S)"

            sudo -n sed -E -i \
                "/^[[:space:]]*127[.]0[.]1[.]1[[:space:]].*${name}([[:space:].]|$)/s/^/# /" \
                /etc/hosts

            sudo -n -u hadoop -H env \
                JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
                /home/hadoop/hadoop-3.4.0/bin/yarn --daemon stop nodemanager

            sudo -n -u hadoop -H env \
                JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
                /home/hadoop/hadoop-3.4.0/bin/yarn --daemon start nodemanager
        fi
    '
done

network_ready=false
for attempt in $(seq 1 60); do
    report=$(as_hadoop "$HADOOP_HOME/bin/yarn" node -list)
    running=$(awk '$2 == "RUNNING" {n++} END {print n+0}' <<< "$report")

    if [ "$running" -eq "${#DATA_NODES[@]}" ]
	then
        network_ready=true
        break
    fi
    sleep 2
done

if [ "$network_ready" != true ]; then
    echo "FAIL: not all NodeManagers are ready" >&2
    exit 1
fi



. /etc/os-release
[ "$ID" = ubuntu ] && {
    [ "$VERSION_ID" = 22.04 ] || [ "$VERSION_ID" = 24.04 ]
} || {
    echo "Required: Ubuntu 22.04 or 24.04" >&2
    exit 1
}

[ -x "$JAVA_HOME/bin/java" ] || { echo 'Java 11 is required' >&2; exit 1; }
"$JAVA_HOME/bin/java" -version

as_hadoop "$HADOOP_HOME/bin/hadoop" version
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls /
as_hadoop "$HADOOP_HOME/bin/yarn" node -list

bash "$PROJECT_DIR/scripts/13_check_yarn.sh"
echo 'OK: requirements are satisfied'

sudo apt-get update
sudo apt-get install -y curl ca-certificates openjdk-11-jdk-headless mysql-server openssl python3

archive="apache-hive-${HIVE_VERSION}-bin.tar.gz"
url="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}"

if ! sudo -u hadoop test -d "$HIVE_HOME"
then
    if ! as_hadoop test -f "/home/hadoop/$archive"
	then
		as_hadoop curl --fail --location --retry 3 "$url/$archive" -o "/home/hadoop/$archive"
	fi
    as_hadoop curl --fail --location --retry 3 "$url/$archive.sha256" -o "/home/hadoop/$archive.sha256"

    expected=$(as_hadoop grep -Eo '[[:xdigit:]]{64}' "/home/hadoop/$archive.sha256" | head -1)
    actual=$(as_hadoop sha256sum "/home/hadoop/$archive" | cut -d ' ' -f 1)
    [ "${expected,,}" = "$actual" ] || { echo 'Checksum mismatch' >&2; exit 1; }
    as_hadoop tar -xzf "/home/hadoop/$archive" -C /home/hadoop
fi

as_hadoop curl --fail --location --retry 3 \
    "https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/$JDBC_VERSION/mysql-connector-j-$JDBC_VERSION.jar" \
    -o "$HIVE_HOME/lib/mysql-connector-j-$JDBC_VERSION.jar"
echo 'OK: Hive and MySQL JDBC driver are installed'
