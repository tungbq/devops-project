#!/bin/bash

# Backend
pwd
echo "Build backend"
pushd backend
docker build -t node-backend .
docker run -d -p 5001:5001 node-backend
popd

# Frontend
pwd
echo "Build frontend"
pushd frontend
docker build -t react-frontend .
docker run -p 3000:80 -e REACT_APP_API_URL='http://localhost:5001' react-frontend
popd

# DB
