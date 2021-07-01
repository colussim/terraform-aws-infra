#!/usr/bin/env bash

set -e
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ssh-keys/id_rsa_aws admin.conf ec2-user@$1:~/.kube/config
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ssh-keys/id_rsa_aws k8sconf/setrole.sh ec2-user@$1:~/setrole.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ssh-keys/id_rsa_aws ec2-user@$1 "chmod 755 ~/setrole.sh;~/setrole.sh"
