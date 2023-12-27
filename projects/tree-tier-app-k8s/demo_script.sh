#!/bin/bash

pwd
echo "Build frontend"
pushd frontend
docker build -t react-frontend .
docker run -p 3000:80 -e REACT_APP_API_URL='http://localhost:5000' react-frontend
popd

pwd
