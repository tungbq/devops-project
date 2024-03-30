# Project: Dockerize python flask application

This project helps us understand and know how to dockerize an application (python flask in this case)

## Overview

### Introduction

- Tech stack: `python`, `docker`, `flask`
- To get basic concept of these tools, you could visit: [**devops-basic**](https://github.com/tungbq/devops-basic) repository

### Prerequisite

- You have docker installed on your machine
- Basic knowledge about docker

## 1-Install docker

- See: [how-to-install-docker](https://github.com/tungbq/devops-basic/tree/main/topics/docker#how-to-install-docker)

## 2-Build the docker image

- Run `docker build -t my-flask-app .`

## 3-Run the Docker container based on the image

- Run `docker run -p 5000:5000 my-flask-app`

## 4-Verify the result

- `curl localhost:5000`
- Or open http://localhost:5000/ in your browser

## 5-Bonus

All in one script could be found at [demo_project.sh](./demo_project.sh)

## Related link

- https://pypi.org/project/Flask/
- https://www.docker.com/
- https://github.com/tungbq/devops-basic/blob/main/topics/docker/README.md
