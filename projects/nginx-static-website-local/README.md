# Project: Build static website with Nginx

- This project helps us learn Nginx and create a static website for that

# Prerequisite

## Basic knowledge about docker

- https://www.docker.com/
- https://github.com/tungbq/devops-basic/blob/main/topics/docker/README.md

## Install docker

- See: https://github.com/tungbq/devops-basic/tree/main/topics/docker#how-to-install-docker

# Playaround with docker

## Build the docker image

- Run `docker build -t my-nginx-static-site .`

## Run the Docker container based on the image

- Run `docker run -d -p 8080:80 my-nginx-static-site`

## Verify the result

- `curl localhost:8080`
- Or open http://localhost:8080/ in your browser

# Related document

- https://docs.nginx.com/
