# Project: Dockerize python flask application

- This project helps us understand and know how to dockerize an application (python flask in this case)
- Technology in used: `python`, `docker`, `flask`

# Prerequisite

## Basic knowledge about docker

- https://www.docker.com/
- https://github.com/tungbq/devops-basic/blob/main/topics/docker/README.md

## Install docker

- See: https://github.com/tungbq/devops-basic/tree/main/topics/docker#how-to-install-docker

# Playaround with docker

## Build the docker image

- Run `docker build -t my-flask-app .`

## Run the Docker container based on the image

- Run `docker run -p 5000:5000 my-flask-app`

## Verify the result

- `curl localhost:5000`
- Or open http://localhost:5000/ in your browser

## AIO script could be found at

- Run the script: [demo_project.sh](./demo_project.sh)

# Bonus

## Related link

- https://pypi.org/project/Flask/
