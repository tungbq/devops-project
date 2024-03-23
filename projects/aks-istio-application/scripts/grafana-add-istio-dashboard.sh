#!/bin/bash

# Address of Grafana
GRAFANA_HOST="http://localhost:4000"
# Login credentials, if authentication is used
GRAFANA_CRED="admin:prom-operator"
# The name of the Prometheus data source to use
GRAFANA_DATASOURCE="Prometheus"
# The version of Istio to deploy
VERSION=1.21.0
# Import all Istio dashboards
for DASHBOARD in 7639 11829 7636 7630 7645 13277; do
  REVISION="$(curl -k https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}\")) | .revision" | tail -n 1)"
  echo "REVISION: $REVISION"
  echo "DASHBOARD: $DASHBOARD"
  echo "https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download"
  curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download >/tmp/dashboard.json
  echo "Importing $(cat /tmp/dashboard.json | jq -r '.title') (revision ${REVISION}, id ${DASHBOARD})..."
  curl -s -k -u "$GRAFANA_CRED" -XPOST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
            \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
            \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
    $GRAFANA_HOST/api/dashboards/import
  echo -e "\nDone\n"
done
