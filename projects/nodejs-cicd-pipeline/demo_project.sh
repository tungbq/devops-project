#!/bin/bash

# Backend
pwd
echo "Build backend"
pushd backend
docker build -t node-backend .
docker run -d -p 3001:3001 node-backend
popd
