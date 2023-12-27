#!/bin/bash

# Backend
pwd
echo "Build backend"
pushd backend
docker build -t node-backend .
docker run -d -p 5000:5000 node-backend
popd

# Frontend
pwd
echo "Build frontend"
pushd frontend
docker build -t react-frontend .
docker run -p 3000:80 -e REACT_APP_API_URL='http://localhost:5000' react-frontend
popd

# DB
