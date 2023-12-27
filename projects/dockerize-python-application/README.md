# Project: Dockerize python flask application

## Install docker

- See: https://github.com/tungbq/devops-basic/tree/main/topics/docker#how-to-install-docker

## Build the docker image

- Run `docker build -t my-flask-app .`

## Run the Docker container based on the image

- Run `docker run -p 5000:5000 my-flask-app`

## AIO script could be found at

- [demo_project.sh](./demo_project.sh)
