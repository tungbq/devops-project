# Project: Configuration Management with Ansible

This project uses Ansible to automate the configuration of multiple "servers" (containers standing in for hosts) with best-practice structure — roles, an inventory, group variables, a Jinja2 template, and a handler — then proves the playbook is genuinely idempotent by running it twice.

## Overview

### Introduction

- Tech stack: `ansible`, `docker`, `nginx`
- To get the basic concept of Ansible, you could visit: [**devops-basics/ansible**](https://github.com/tungbq/devops-basics/blob/main/topics/ansible/README.md)
- The demo targets are plain `ubuntu:22.04` containers reached via Ansible's `community.docker` connection plugin — no SSH keys, no cloud account, no VMs to provision

### Prerequisite

- You have `docker` installed on your machine
- Basic knowledge about Ansible (inventory, playbook, role, task)

### What "best practice" means here

- **Roles, not one giant playbook** — `common` (baseline every host gets) and `webserver` (nginx + a templated page) are separate, reusable roles
- **Inventory-scoped group vars**, not hardcoded values — `app_environment` lives in `inventory/group_vars/all.yml`, not inline in a task
- **Handlers, not unconditional restarts** — nginx only reloads when the templated config actually changed, via `notify`
- **Idempotency, proven not assumed** — the demo runs the playbook twice; the second run reports `changed=0` for every task
- **Explicit `changed_when`** on raw/command tasks — passes `ansible-lint`'s `production` profile clean

## 1-Install Ansible

- `python3 -m pip install ansible-core`
- Then install the Docker connection plugin's collection: `ansible-galaxy collection install community.docker`
- Verify: `ansible --version`

## 2-Spin up the demo target hosts

- Run `docker run -d --name ansible-demo-web1 ubuntu:22.04 sleep infinity` and the same for `ansible-demo-web2` — two identical, unconfigured "servers"
- They're listed in [`inventory/hosts.ini`](./inventory/hosts.ini) with `ansible_connection=community.docker.docker`, so Ansible talks to them via `docker exec` — no SSH setup needed for this demo

## 3-Run the playbook

- Run `ansible-playbook -i inventory/hosts.ini playbooks/site.yml`
- What happens, in order (see [`playbooks/site.yml`](./playbooks/site.yml)):
  1. `pre_tasks` bootstraps `python3` and `sudo` via a `raw` command — these minimal images have neither, and Ansible's own modules (including fact-gathering) need Python
  2. facts are gathered explicitly, now that Python exists
  3. the `common` role updates apt, installs baseline packages, and drops a marker file
  4. the `webserver` role installs nginx, templates `index.html` from [`roles/webserver/templates/index.html.j2`](./roles/webserver/templates/index.html.j2), and starts nginx
  5. because the template changed, the `Reload nginx` handler fires at the end of the play

## 4-Verify both hosts

- `docker exec ansible-demo-web1 curl -s localhost` and the same for `web2`
- Both serve the same markup with a different `{{ inventory_hostname }}` — one role, two consistently-configured hosts

## 5-Prove idempotency

- Run the exact same command again: `ansible-playbook -i inventory/hosts.ini playbooks/site.yml`
- Expected: `changed=0` for both hosts in the play recap — nothing to do, because nothing drifted
- Change `app_environment` in [`inventory/group_vars/all.yml`](./inventory/group_vars/all.yml) and run a third time: only the templated file (and the handler it notifies) shows as `changed` — everything else stays `ok`

## 6-Bonus

All of the above, scripted end-to-end (fresh containers → configure → verify → prove idempotency), is in [demo_project.sh](./demo_project.sh).

## Related link

- https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html
- https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html
- https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html
- https://galaxy.ansible.com/ui/repo/published/community/docker/
- https://github.com/tungbq/devops-basics/blob/main/topics/ansible/README.md
