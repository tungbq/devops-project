<h1 align="center">DevOps Project</h1>

<p align="center">Collection of DevOps projects to level up your DevOps skills 💝</p>
<p align="center">
  <a href="https://img.shields.io/github/last-commit/tungbq/devops-project/main"><img alt="last commit" src="https://img.shields.io/github/last-commit/tungbq/devops-project/main" /></a>
  <a href="https://github.com/tungbq/devops-project/releases"><img alt="devops-project release" src="https://img.shields.io/github/release/tungbq/devops-project.svg" /></a>
  <a href="https://github.com/tungbq/devops-project/stargazers"><img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/tungbq/devops-project"/></a>
</p>

## Basic of DevOps

- To get the basic concepts of DevOps and related tools, visit: **[tungbq/devops-basics](https://github.com/tungbq/devops-basics)**

## Projects

This is the **third** repo of my DevOps trio repositories: [**tungbq/devops-basics**](https://github.com/tungbq/devops-basics) ↔️ [devops-practice](https://github.com/tungbq/devops-practice) ↔️ [**tungbq/devops-project**](https://github.com/tungbq/devops-project), designed to help you learn, practice, and apply DevOps.

### Check out [projects](./projects/) list below, grouped by category 🔥

#### 🐳 Containers & Images

| ID  | Project                       | Content                                                                   | Status  |
| :-- | :----------------------------- | :------------------------------------------------------------------------ | :------ |
| 01  | Dockerize python application  | [dockerize-python-application](./projects/dockerize-python-application/) | ✔️ Done |
| 02  | Nginx Static Website Local    | [nginx-static-website-local](./projects/nginx-static-website-local/)     | ✔️ Done |

#### 🔁 CI/CD Pipelines

| ID  | Project                                        | Content                                                                              | Status  |
| :-- | :---------------------------------------------- | :------------------------------------------------------------------------------------ | :------ |
| 03  | NodeJS project with CICD                       | [nodejs-cicd-pipeline](./projects/nodejs-cicd-pipeline/)                             | ✔️ Done |
| 12  | Deploy and Setup Jenkins on Kubernetes cluster | [jenkins-on-k8s](https://github.com/tungbq/K8sHub/tree/main/hands-on/jenkins-on-k8s) (external repo) | ✔️ Done |

#### 🏗️ Infrastructure as Code (Terraform)

| ID  | Project                                    | Content                                                                       | Status  |
| :-- | :------------------------------------------ | :------------------------------------------------------------------------------ | :------ |
| 05  | Create Windows instance on AWS             | [terraform-aws-windows-instance](./projects/terraform-aws-windows-instance/)   | ✔️ Done |
| 07  | Create free VPN server on AWS              | [terraform-free-vpn-on-aws](./projects/terraform-free-vpn-on-aws/)             | ✔️ Done |
| 08  | Provision fresh AKS cluster with Terraform | [terraform-fresh-aks-cluster](./projects/terraform-fresh-aks-cluster/)         | ✔️ Done |

#### ☸️ Kubernetes & Container Orchestration

| ID  | Project                               | Content                                                               | Status  |
| :-- | :-------------------------------------- | :----------------------------------------------------------------------- | :------ |
| 06  | Create k8s cluster aws with kubeadm   | [create-k8s-cluster-aws-ec2](./projects/create-k8s-cluster-aws-ec2/) | ✔️ Done |
| 09  | Deploy and monitor application on AKS | [aks-deploy-monitor-app](./projects/aks-deploy-monitor-app/)         | ✔️ Done |

#### 🕸️ Service Mesh

| ID  | Project                                      | Content                                                       | Status  |
| :-- | :--------------------------------------------- | :--------------------------------------------------------------- | :------ |
| 10  | Deploy application on AKS with Istio         | [aks-istio-application](./projects/aks-istio-application/)   | ✔️ Done |
| 11  | Nginx ingress with Istio service mesh on AKS | [aks-nginx-with-istio](./projects/aks-nginx-with-istio/)     | ✔️ Done |

#### ☁️ Cloud Architecture

| ID  | Project                        | Content                                                                  | Status  |
| :-- | :------------------------------- | :--------------------------------------------------------------------------- | :------ |
| 04  | AWS 3 tiers web                | [aws-tree-tiers-web](./projects/aws-tree-tiers-web/)                       | ✔️ Done |
| 13  | Azure Static Web Apps (Simple) | [azure-static-web-apps-simple](./projects/azure-static-web-apps-simple)    | ✔️ Done |

## 🗺️ Roadmap / Planned Projects

Sourced from our open [`project`-labeled issues](https://github.com/tungbq/devops-project/issues?q=is%3Aissue+is%3Aopen+label%3Aproject) ⏩ — pick one and open a PR, see [Contributing](#contributing).

#### 🔁 CI/CD Pipelines

- [#5 Simple CI pipeline with Github Action](https://github.com/tungbq/devops-project/issues/5)
- [#32 Jenkins CI pipeline for Github repo](https://github.com/tungbq/devops-project/issues/32)
- [#71 Build a CI/CD pipeline for microservices on Kubernetes](https://github.com/tungbq/devops-project/issues/71)

#### 🤖 Configuration Management

- [#14 Configuration Management with Ansible](https://github.com/tungbq/devops-project/issues/14)
- [#65 Create an `ansible` project with best practice](https://github.com/tungbq/devops-project/issues/65) — likely duplicate of #14, worth merging

#### ☸️ Kubernetes & Container Orchestration

- [#8 Microservices Orchestration](https://github.com/tungbq/devops-project/issues/8)
- [#9 3 tier app with k8s](https://github.com/tungbq/devops-project/issues/9)
- [#70 Deploy Kubernetes using Kubespray](https://github.com/tungbq/devops-project/issues/70)
- [#63 Deploy an AKS cluster using Terraform](https://github.com/tungbq/devops-project/issues/63) — appears already covered by done project 08 above, worth verifying and closing
- [#88 Deploy and monitor application on AKS cluster](https://github.com/tungbq/devops-project/issues/88) — appears already covered by done project 09 above, worth verifying and closing

#### ☁️ Cloud Architecture

- [#6 Deploy a static website to AWS S3](https://github.com/tungbq/devops-project/issues/6)

## Contributing

- If you find this repository helpful, kindly consider showing your appreciation by giving it a star ⭐ Thanks! 💖
- See: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Looking for the issue to work on? Check the list of our open issues [**good first issue**](https://github.com/tungbq/devops-project/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
- Feel free to open a new issue if you want to request more content about DevOps
