#!/bin/bash

usage() {
    cat << EOF
Usage:
 $0 [-h|--help] -s|--state STATE

Options:
 -h, -?, --help     display this help
 -s, --state STATE  Show units of state STATE

EOF
    exit "$1"
}

set -eo pipefail

opts=$(getopt -o h,s: --long help,state: -n "$0" -- "$@") || usage 1
eval set -- "$opts"
while true; do
  case "$1" in
    -h | --help ) usage 0; shift ;;
    -s | --state ) state="$2"; shift 2 ;;
    * ) break ;;
  esac
done

if [[ -z $state ]]; then
    echo "Need state parameter, e.g. 'failed' or 'masked'" >&2
    exit 2
fi

UNITS=$(systemctl --no-legend --state="$state" --plain)
UNITS_COUNT=$(echo "$UNITS" | grep -v "^$" | wc -l ||:)
UNITS_NAMES=$(echo -n "$UNITS" | cut -d" " -f 1 | xargs -I{} basename {} .service)
TAGS_PER_UNIT=""

I=1
for UNIT in $UNITS_NAMES; do
    if [[ $I -gt 1 ]]; then
        TAGS_PER_UNIT="$TAGS_PER_UNIT,"
    fi
    TAGS_PER_UNIT="${TAGS_PER_UNIT}unit_$I=$UNIT"
    I=$(($I+1))
done
if [[ $I -gt 1 ]]; then
    UNITS_LIST=$(echo $UNITS_NAMES | sed 's/\ /\\,\\ /g')
    UNITS_HUMAN_TAG=",units=${UNITS_LIST}"
    UNITS_TAGS="${UNITS_HUMAN_TAG},${TAGS_PER_UNIT}"
fi

hostname=$(hostname -f)
[[ $hostname ]] || hostname=$(hostname)
echo systemd_"${state}",machine="${hostname}${UNITS_TAGS}" "${state}"="${UNITS_COUNT}i"
