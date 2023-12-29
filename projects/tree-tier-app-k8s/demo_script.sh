#!/bin/bash

# Backend
pwd
echo "Build backend"
pushd backend
docker build -t node-backend .
docker run -d -p 3001:3001 node-backend
popd

# Frontend
pwd
echo "Build frontend"
pushd frontend
docker build -t react-frontend .
docker run -p 3000:80 -e REACT_APP_API_URL='http://localhost:3001' react-frontend
popd

# DB
