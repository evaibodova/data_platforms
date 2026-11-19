#!/bin/bash
source "$(dirname "$0")/hive_variables.sh"

as_hadoop tee /home/hadoop/hive-env.sh > /dev/null <<EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HIVE_HOME=$HIVE_HOME
export HIVE_CONF_DIR=$HIVE_CONF_DIR
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HIVE_HOME/bin
EOF

if ! sudo -u hadoop grep -q '^source /home/hadoop/hive-env.sh$' /home/hadoop/.profile
then
    echo 'source /home/hadoop/hive-env.sh' | as_hadoop tee -a /home/hadoop/.profile > /dev/null
fi

if [ -f "$PROJECT_DIR/.env" ]
then
    source "$PROJECT_DIR/.env"
fi

if [ -z "${METASTORE_PASSWORD:-}" ]
then
    (umask 077; printf '\nMETASTORE_PASSWORD=%s\n' "$(openssl rand -hex 24)" >> "$PROJECT_DIR/.env")
fi

chmod 600 "$PROJECT_DIR/.env"
source "$PROJECT_DIR/.env"

[[ "$METASTORE_PASSWORD" =~ ^[0-9a-f]{48}$ ]] || { echo 'Expected 48 hex password characters' >&2; exit 1; }

sudo systemctl enable --now mysql
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS hive_metastore CHARACTER SET latin1;
CREATE USER IF NOT EXISTS 'hive'@'127.0.0.1' IDENTIFIED BY '$METASTORE_PASSWORD';
ALTER USER 'hive'@'127.0.0.1' IDENTIFIED BY '$METASTORE_PASSWORD';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'127.0.0.1';
EOF

echo 'OK: MySQL metastore database is ready'

source "$PROJECT_DIR/.env"
[[ "$METASTORE_PASSWORD" =~ ^[0-9a-f]{48}$ ]]

for file in core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml
do
    as_hadoop cp "$HADOOP_CONF_DIR/$file" "$HIVE_CONF_DIR/$file"
done

as_hadoop tee "$HIVE_CONF_DIR/hive-site.xml" > /dev/null <<EOF
<configuration>
	<property>
		<name>javax.jdo.option.ConnectionURL</name>
		<value>jdbc:mysql://127.0.0.1:3306/hive_metastore?createDatabaseIfNotExist=false&amp;useSSL=false&amp;allowPublicKeyRetrieval=true&amp;serverTimezone=UTC</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionDriverName</name>
		<value>com.mysql.cj.jdbc.Driver</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionUserName</name>
		<value>hive</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionPassword</name>
		<value>$METASTORE_PASSWORD</value>
	</property>
	<property>
		<name>hive.metastore.uris</name>
		<value>thrift://$EDGE_NODE:9083</value>
	</property>
	<property>
		<name>hive.metastore.warehouse.dir</name>
		<value>/user/hive/warehouse</value>
	</property>
	<property>
		<name>hive.metastore.warehouse.external.dir</name>
		<value>/user/hive/warehouse/external</value>
	</property>
	<property>
		<name>hive.metastore.schema.verification</name>
		<value>true</value>
	</property>
	<property>
		<name>datanucleus.schema.autoCreateAll</name>
		<value>false</value>
	</property>
	<property>
		<name>hive.server2.thrift.bind.host</name>
		<value>$EDGE_NODE</value>
	</property>
	<property>
		<name>hive.server2.thrift.port</name>
		<value>10000</value>
	</property>
  	<property>
		<name>hive.server2.webui.host</name>
		<value>$EDGE_NODE</value>
	</property>
  	<property>
		<name>hive.server2.webui.port</name>
		<value>10002</value>
	</property>
	<property>
		<name>hive.server2.enable.doAs</name>
		<value>false</value>
	</property>
	<property>
		<name>hive.security.authorization.enabled</name>
		<value>false</value>
	</property>
	<property>
		<name>hive.server2.authentication</name>
		<value>NONE</value>
	</property>
	<property>
		<name>hive.execution.engine</name>
		<value>mr</value>
	</property>
	<property>
		<name>hive.support.concurrency</name>
		<value>false</value>
	</property>
	<property>
		<name>hive.metastore.event.db.notification.api.auth</name>
		<value>false</value>
	</property>
</configuration>
EOF
as_hadoop chmod 600 "$HIVE_CONF_DIR/hive-site.xml"

as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p /tmp /user/hive/warehouse/external /user/hadoop/hive-input
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -chmod 1777 /tmp
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -chmod -R 775 /user/hive/warehouse
as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls /user/hive

tables=$(sudo mysql -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='hive_metastore';")
if [ "$tables" = 0 ]
then
    as_hadoop "$HIVE_HOME/bin/schematool" -dbType mysql -initSchema
else
    echo 'Metastore has tables; checking the existing schema (no reinitialization)'
fi

as_hadoop "$HIVE_HOME/bin/schematool" -dbType mysql -info
as_hadoop "$HIVE_HOME/bin/schematool" -dbType mysql -validate
