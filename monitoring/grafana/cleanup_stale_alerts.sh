#!/bin/bash -e

# This script cleans up stale alerts by filling a special provisioning file which instructs grafana to delete them.
# Stale alerts are determined by comparing present alert UIDs via the grafana api with provisioned alerts present in the filesystem of our alert provisioning.
# To execute these changes, a privileged grafana instance admin account is needed and can be supplied via arguments.

GRAFANA_URL="https://stats.openqa-monitor.qa.suse.de"
GRAFANA_USERNAME="$1"
GRAFANA_PASSWORD="$2"

PROVISIONED_ALERTS_DIR="/etc/grafana/provisioning/alerting"
PROVISIONED_ALERTS=$(curl -s "${GRAFANA_URL}/api/v1/provisioning/alert-rules" -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" | jq -r '.[].uid')

DELETION_FILE=$(mktemp -p /etc/grafana/provisioning/alerting deletion.XXXXXXXXXX.yaml)

function generate_cleanup_file {
	chmod o+r "${DELETION_FILE}"
	echo "deleteRules:" >> "${DELETION_FILE}"
	for rule_uid in $PROVISIONED_ALERTS; do
		if ! grep -qr "${rule_uid}" "${PROVISIONED_ALERTS_DIR}"; then
			cat <<EOT >> "${DELETION_FILE}"
  - orgId: 1
    uid: ${rule_uid}
EOT
		fi
	done
}

function reload_grafana {
	curl -X POST -H "Content-Type: application/json" -s "${GRAFANA_URL}/api/admin/provisioning/alerting/reload" -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}"
}

function cleanup {
	rm "${DELETION_FILE}"
	reload_grafana
}

trap cleanup EXIT
generate_cleanup_file
reload_grafana
# cleanup and second reloading happens implicit at exit
