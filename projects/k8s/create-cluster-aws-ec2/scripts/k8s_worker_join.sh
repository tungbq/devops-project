#!/bin/bash

cat /etc/os-release
token="$1"
echo "Runing command $token"
sudo "$token"
