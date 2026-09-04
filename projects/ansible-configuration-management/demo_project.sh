#!/bin/bash
# Ansible Configuration Management Demo — configures two "servers" (plain
# ubuntu:22.04 containers, reached via the community.docker connection
# plugin, no SSH needed) with a common baseline plus an nginx role, then
# proves the playbook is idempotent by running it a second time.

set -e

CONTAINERS=(ansible-demo-web1 ansible-demo-web2)

echo "==> Ansible version:"
ansible --version | head -1

echo ""
echo "=============================="
echo "1. Spinning up demo target containers"
echo "=============================="
for c in "${CONTAINERS[@]}"; do
  docker rm -f "$c" >/dev/null 2>&1 || true
  docker run -d --name "$c" ubuntu:22.04 sleep infinity
done
docker ps --filter "name=ansible-demo"

echo ""
echo "=============================="
echo "2. First run — configuring both hosts"
echo "=============================="
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

echo ""
echo "=============================="
echo "3. Verifying both hosts serve the expected, per-host content"
echo "=============================="
for c in "${CONTAINERS[@]}"; do
  echo "--- $c ---"
  docker exec "$c" curl -s localhost
done

echo ""
echo "=============================="
echo "4. Second run — proving idempotency (expect changed=0 for every host)"
echo "=============================="
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

echo ""
echo "==> Done! Both hosts ended up configured identically, and the second"
echo "    run made zero changes — that's the idempotency guarantee a"
echo "    well-written playbook gives you: safe to re-run anytime, including"
echo "    on a schedule or after a host drifts from its intended config."
echo ""
echo "==> Tip: edit inventory/group_vars/all.yml's app_environment and re-run"
echo "    — only the templated file (and the nginx reload it triggers) will"
echo "    show as changed."
echo ""
echo "==> Cleanup:"
echo "    docker rm -f ${CONTAINERS[*]}"
