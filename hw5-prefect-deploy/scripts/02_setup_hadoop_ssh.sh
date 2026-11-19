#!/bin/bash
set -e

source "$(dirname "$0")/variables.sh"

if [ "$(hostname)" != "$EDGE_NODE" ]
then
    echo "Error: script should be run from the edge node" >&2
    exit 1
fi

sudo -u hadoop mkdir -p  /home/hadoop/.ssh
sudo chmod 700 /home/hadoop/.ssh
sudo chown -R hadoop:hadoop /home/hadoop/.ssh

if [ ! -f /home/hadoop/.ssh/id_ed25519 ]
then
  sudo -u hadoop ssh-keygen -t ed25519 -f /home/hadoop/.ssh/id_ed25519 -N ""
fi

sudo -u hadoop cp /home/hadoop/.ssh/id_ed25519.pub /home/hadoop/.ssh/authorized_keys

sudo chmod 600 /home/hadoop/.ssh/id_ed25519
sudo chmod 644 /home/hadoop/.ssh/id_ed25519.pub
sudo chmod 600 /home/hadoop/.ssh/authorized_keys

mkdir -p hadoop_ssh/.ssh

sudo cp /home/hadoop/.ssh/id_ed25519 hadoop_ssh/.ssh/
sudo cp /home/hadoop/.ssh/id_ed25519.pub hadoop_ssh/.ssh/
sudo cp /home/hadoop/.ssh/authorized_keys hadoop_ssh/.ssh/

sudo chown -R team:team hadoop_ssh/.ssh

for node in "${DATA_NODES[@]}"
do
    ssh "$node" 'mkdir -p /home/team/hadoop_ssh'
    scp -i /home/team/.ssh/team_internal hadoop_ssh/.ssh/* "$node":/home/team/hadoop_ssh
done

for node in "${DATA_NODES[@]}"
do
    echo "===== $node ====="
    ssh "$node" '
        sudo -u hadoop mkdir -p /home/hadoop/.ssh
        sudo mv /home/team/hadoop_ssh/* /home/hadoop/.ssh
        sudo chown -R hadoop:hadoop /home/hadoop/.ssh
        sudo chmod 700 /home/hadoop/.ssh
        sudo chmod 600 /home/hadoop/.ssh/id_ed25519
        sudo chmod 644 /home/hadoop/.ssh/id_ed25519.pub
        sudo chmod 600 /home/hadoop/.ssh/authorized_keys
        sudo rmdir /home/team/hadoop_ssh
        '
  echo "done"
done

rm -rf hadoop_ssh/.ssh