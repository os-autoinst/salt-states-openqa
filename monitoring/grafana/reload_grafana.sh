#!/bin/bash
set -euo pipefail

function get_grafana_config_value() {
  local grafana_config_file="$1"
  local config_key="$2"
  grep "^${config_key}\s*=\s*.\+$" "${grafana_config_file}" | head -n1 | cut -d "=" -f 2 | xargs
}

function grafana_req() {
  local api_endpoint="$1"
  ! curl -u "${HTTP_USERNAME}:${HTTP_PASSWORD}" -X POST --unix-socket "${GRAFANA_SOCKET_PATH}" "${GRAFANA_ROOT_URL/https/http}/${api_endpoint}" -s | grep -i error
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]
Options:
 -h, --help         display this help
 -u, --username     username used for the http request
 -p, --password     password used for the http request
EOF
    exit "$1"
}

main() {
    opts=$(getopt -o "h u: p:" -l "help username: password:" -n "$0" -- "$@") || usage 1
    eval set -- "$opts"
    while true; do
        case "$1" in
            -h | --help) usage 0 ;;
	    -u | --username) HTTP_USERNAME=$2; shift 2;;
	    -p | --password) HTTP_PASSWORD=$2; shift 2;;
            --)
                shift
                break
                ;;
            *) break ;;
        esac
    done

    HTTP_USERNAME=${HTTP_USERNAME:-admin}
    HTTP_PASSWORD=${HTTP_PASSWORD:-}
    GRAFANA_CONFIG="${CONF_FILE:-/etc/grafana/grafana.ini}" # should be set by the service-file for grafana, otherwise we take a sane default
    PROVISIONING_TO_RELOAD="dashboards datasources plugins access-control alerting"
    GRAFANA_SOCKET_PATH=$(get_grafana_config_value "${GRAFANA_CONFIG}" "socket")
    GRAFANA_ROOT_URL=$(get_grafana_config_value "${GRAFANA_CONFIG}" "root_url")

    for config in ${PROVISIONING_TO_RELOAD}; do
      grafana_req "api/admin/provisioning/${config}/reload"
    done
}

caller 0 > /dev/null || main "$@"
