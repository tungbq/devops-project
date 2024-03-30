# Project: NodeJS project with CICD

This project aims to develop a Node.js application with CI/CD integration.

## Overview

### Introduction

- Tech stack: `Node.js`, `Docker`
- To gain a basic understanding of Docker, you could visit: [**Docker**](https://www.docker.com/) and [**devops-basic/docker**](https://github.com/tungbq/devops-basic/blob/main/topics/docker/README.md) repository

### Prerequisite

- Basic knowledge about Docker
- Tools: `docker`, `curl`

## 1-Setup Environment

### 1.1-Build Docker Image

- Run `docker build -t node-backend .`

### 1.2-Run Docker Container

- Run `docker run -d -p 3001:3001 node-backend`

### 1.3-Verify Installation

- Execute `curl localhost:3001` in your terminal
- Alternatively, open [http://localhost:3001/](http://localhost:3001/) in your browser

## 2-Continuous Integration (CI) Pipeline Setup

- Check the GitHub workflow: [nodejs-cicd-pipeline.yml](https://github.com/tungbq/devops-project/blob/main/.github/workflows/nodejs-cicd-pipeline.yml)
