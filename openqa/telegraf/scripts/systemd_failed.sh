#!/bin/bash
FAILED_UNITS=$(systemctl --no-legend --failed --plain)
FAILED_UNITS_COUNT=$(echo "$FAILED_UNITS" | wc -l)
FAILED_UNITS_NAME=$(echo "$FAILED_UNITS" | cut -d" " -f 1 | xargs -I{} basename {} .service)
FAILED_UNITS_TAGS=""
I=1
for FAILED_UNIT in $FAILED_UNITS_NAME; do
	if [[ $I -gt 1 ]]; then
		FAILED_UNITS_TAGS="$FAILED_UNITS_TAGS,"
	fi
	FAILED_UNITS_TAGS="${FAILED_UNITS_TAGS}unit_$I=$FAILED_UNIT"
	I=$(($I+1))
done
FAILED_UNITS_LIST=$(echo $FAILED_UNITS_NAME | sed 's/\ /\\,\\ /g')
echo systemd_failed_test,machine=$(hostname -f),units=${FAILED_UNITS_LIST},${FAILED_UNITS_TAGS} failed=${FAILED_UNITS_COUNT}i
