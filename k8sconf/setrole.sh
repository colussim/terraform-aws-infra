#!/usr/bin/env bash

/usr/bin/kubectl label node $HOST node-role.kubernetes.io/worker=worker
