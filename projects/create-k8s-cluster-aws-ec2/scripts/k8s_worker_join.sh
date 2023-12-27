#!/bin/bash
set -x
token="$@"
echo "Runing command:"
echo $token
sudo $token
