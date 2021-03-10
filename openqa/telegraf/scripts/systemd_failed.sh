#!/bin/bash
FAILED_UNITS=$(systemctl --no-legend --failed --plain)
FAILED_UNITS_COUNT=$(echo "$FAILED_UNITS" | grep -v "^$" | wc -l)
FAILED_UNITS_NAMES=$(echo -n "$FAILED_UNITS" | cut -d" " -f 1 | xargs -I{} basename {} .service)
TAGS_PER_UNIT=""

I=1
for FAILED_UNIT in $FAILED_UNITS_NAMES; do
	if [[ $I -gt 1 ]]; then
		TAGS_PER_UNIT="$TAGS_PER_UNIT,"
	fi
	TAGS_PER_UNIT="${TAGS_PER_UNIT}unit_$I=$FAILED_UNIT"
	I=$(($I+1))
done
if [[ $I -gt 1 ]]; then
	FAILED_UNITS_LIST=$(echo $FAILED_UNITS_NAMES | sed 's/\ /\\,\\ /g')
	FAILED_UNITS_HUMAN_TAG=",units=${FAILED_UNITS_LIST}"
	FAILED_UNITS_TAGS="${FAILED_UNITS_HUMAN_TAG},${TAGS_PER_UNIT}"
fi

echo systemd_failed_test,machine=$(hostname -f)${FAILED_UNITS_TAGS} failed=${FAILED_UNITS_COUNT}i
