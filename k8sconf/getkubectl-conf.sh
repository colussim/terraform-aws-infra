#!/usr/bin/env bash

set -e

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ssh-keys/id_rsa_aws ec2-user@$1:~/.kube/config admin.conf 
