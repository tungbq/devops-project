# NodeJS project with CICD

## Prerequisite

### Basic knowledge about docker

- https://www.docker.com/
- https://github.com/tungbq/devops-basic/blob/main/topics/docker/README.md

### Install docker

- See: https://github.com/tungbq/devops-basic/tree/main/topics/docker#how-to-install-docker

## Playaround with this project

### Build the docker image

- Run `docker build -t node-backend .`

### Run the Docker container based on the image

- Run `docker run -d -p 3001:3001 node-backend`

### Verify the result

- `curl localhost:3001`
- Or open http://localhost:3001/ in your browser

## Create CI pipeline for this app
- Check the GitHub workflow: https://github.com/tungbq/devops-project/blob/main/.github/workflows/nodejs-cicd-pipeline.yml
