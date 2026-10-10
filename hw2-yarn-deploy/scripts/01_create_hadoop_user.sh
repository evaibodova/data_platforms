#!/bin/bash

source "$(dirname "$0")/variables.sh"
source "$(dirname "$0")/../.env"

for node in "${ALL_NODES[@]}"
do
    echo "===== $node ====="
    if [ "$node" = "$(hostname)" ]
    then
        if ! id hadoop &>/dev/null
        then
            sudo useradd -m -s /bin/bash hadoop
            echo "the user haddop has been created"
        else
            echo "the user hadoop already exists"
        fi
    printf 'hadoop:%s\n' "$HADOOP_PASSWORD" | sudo chpasswd
    echo "the password has been set"
    else
    ssh "$node" "
      if ! id hadoop &>/dev/null
      then
        sudo useradd -m -s /bin/bash hadoop
        echo 'the user hadoop has been created'
      else
        echo 'the user hadoop already exists'
      fi
    "

    printf 'hadoop:%s\n' "$HADOOP_PASSWORD" \
      | ssh "$node" 'sudo chpasswd'

    echo "the password has been set"
  fi
    echo "OK: $node"
    echo
done

echo "all the nodes have been processed"