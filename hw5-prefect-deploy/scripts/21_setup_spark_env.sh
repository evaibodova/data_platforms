#!/bin/bash

source "$(dirname "$0")/variables.sh"

as_hadoop tee "$SPARK_CONF_DIR/spark-env.sh" > /dev/null <<ENV
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export YARN_CONF_DIR=$HADOOP_CONF_DIR
export SPARK_HOME=$SPARK_HOME
export SPARK_DIST_CLASSPATH=\$SPARK_HOME/jars/*:\$(\$HADOOP_HOME/bin/hadoop classpath)
export PATH=\$PATH:\$HADOOP_HOME/bin:\$SPARK_HOME/bin
ENV

as_hadoop tee "$SPARK_CONF_DIR/spark-defaults.conf" > /dev/null <<CONF
spark.master                          yarn
spark.submit.deployMode               client
spark.driver.host                     $EDGE_NODE
spark.driver.bindAddress              0.0.0.0
spark.driver.memory                   1g
spark.executor.memory                 1g
spark.executor.cores                  1
spark.executor.instances              2
spark.dynamicAllocation.enabled       false
spark.yarn.populateHadoopClasspath    true
spark.sql.shuffle.partitions          4
spark.sql.catalogImplementation       in-memory
spark.sql.sources.partitionColumnTypeInference.enabled false
CONF

as_hadoop mkdir -p /home/hadoop/spark-hw4
as_spark "$SPARK_HOME/bin/spark-submit" --version
echo "OK: Spark environment is configured for YARN"
