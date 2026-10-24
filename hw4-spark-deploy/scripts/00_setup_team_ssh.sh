#!/bin/bash

chmod 700 ~/.ssh

source "$(dirname "$0")/variables.sh"

cat >> ~/.ssh/config <<EOF
Host ${DATA_NODES[*]}
    User team
    IdentityFile ~/.ssh/team_internal
EOF

chmod 600 ~/.ssh/config
