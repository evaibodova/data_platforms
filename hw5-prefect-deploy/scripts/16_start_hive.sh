#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"

for service in metastore hiveserver2
do
    dependency=mysql.service
    [ "$service" != hiveserver2 ] || dependency=hive-metastore.service
    sudo tee "/etc/systemd/system/hive-$service.service" > /dev/null <<EOF
[Unit]
Description=Apache Hive $service
After=network-online.target $dependency
Requires=$dependency
[Service]
Type=simple
User=hadoop
Group=hadoop
WorkingDirectory=/home/hadoop
Environment=JAVA_HOME=$JAVA_HOME
Environment=HADOOP_HOME=$HADOOP_HOME
Environment=HADOOP_CONF_DIR=$HADOOP_CONF_DIR
Environment=HIVE_HOME=$HIVE_HOME
Environment=HIVE_CONF_DIR=$HIVE_CONF_DIR
ExecStart=$HIVE_HOME/bin/hive --service $service
Restart=on-failure
RestartSec=10
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
EOF
done

sudo systemctl daemon-reload
sudo systemctl enable hive-metastore hive-hiveserver2
sudo systemctl stop hive-hiveserver2
sudo systemctl restart hive-metastore
sudo systemctl start hive-hiveserver2

for attempt in $(seq 1 90)
do
    if beeline -e 'SHOW DATABASES;' > /dev/null 2>&1
	then
        echo 'OK: HiveServer2 accepts SQL queries'
		exit 0
    fi
    sleep 5
done

echo 'FAIL: Hive startup timeout. See journalctl -u hive-metastore -u hive-hiveserver2' >&2
exit 1
