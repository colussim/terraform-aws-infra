#!/usr/bin/env bash

set -e

#eval "$(jq -r '@sh "HOST=\(.host)"')"

# Fetch the join command
CMD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ec2-user@$HOST kubeadm token create --print-join-command)

# Produce a JSON object containing the join command
jq -n --arg command "$CMD" '{"command":$command}'
