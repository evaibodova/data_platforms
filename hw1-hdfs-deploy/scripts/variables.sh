#!/bin/bash

HADOOP_VERSION="3.4.0"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

EDGE_NODE="team-03-en"
NAME_NODE="team-03-nn"
SECONDARY_NAME_NODE="team-03-en"
DATA_NODES=(
    "team-03-nn"
    "team-03-00"
    "team-03-01"
)

ALL_NODES=(
    "team-03-en"
    "team-03-nn"
    "team-03-00"
    "team-03-01"
)
