#!/bin/bash
set -euo pipefail

# This script cleans up stale alerts by filling a special provisioning file which instructs grafana to delete them.
# Stale alerts are determined by comparing present alert UIDs via the grafana api with provisioned alerts present in the filesystem of our alert provisioning.
# To execute these changes, a privileged grafana instance admin account is needed and must be supplied via arguments: <username> <password>

GRAFANA_URL="https://monitor.qa.suse.de"
GRAFANA_USERNAME="$1"
GRAFANA_PASSWORD="$2"

PROVISIONED_ALERTS_DIR="/etc/grafana/provisioning/alerting"
PROVISIONED_ALERTS=$(curl -sSf "${GRAFANA_URL}/api/v1/provisioning/alert-rules" -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" | jq -r '.[].uid')

STALE_ALERTS=""
for rule_uid in $PROVISIONED_ALERTS; do
	grep -qrF -- "${rule_uid}" "${PROVISIONED_ALERTS_DIR}" || STALE_ALERTS+="${rule_uid} "
done

if [[ -z "${STALE_ALERTS}" ]]; then
	echo "No stale alert rules found"
	exit 0
fi

DELETION_FILE=$(mktemp -p "${PROVISIONED_ALERTS_DIR}" deletion.XXXXXXXXXX.yaml)

function generate_cleanup_file {
	chmod o+r "${DELETION_FILE}"
	echo "deleteRules:" >> "${DELETION_FILE}"
	for rule_uid in $STALE_ALERTS; do
		cat <<EOT >> "${DELETION_FILE}"
  - orgId: 1
    uid: ${rule_uid}
EOT
	done
}

function reload_grafana {
	curl -X POST -H "Content-Type: application/json" -sSf "${GRAFANA_URL}/api/admin/provisioning/alerting/reload" -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}"
}

function cleanup {
	rm "${DELETION_FILE}"
	reload_grafana
}

trap cleanup EXIT
generate_cleanup_file
reload_grafana
echo "Deleted stale alert rules: ${STALE_ALERTS}"
# cleanup and second reloading happens implicit at exit
