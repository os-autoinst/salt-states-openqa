#!/bin/bash -e
# Fails on any E! or W! line emitted while loading the telegraf configuration

strict_env_flags=()
# --strict-env-handling is only known since telegraf 1.38
if telegraf --help 2>&1 | grep -q -- '--strict-env-handling'; then
	strict_env_flags=(--strict-env-handling)
fi

output=$(timeout --kill-after=1m 5m telegraf --test "${strict_env_flags[@]}" \
	--config /etc/telegraf/telegraf.conf --config-directory /etc/telegraf/telegraf.d/ 2>&1) || status=$?
printf '%s\n' "$output"
if [[ ${status:-0} -ne 0 ]] || grep -qE ' (E|W)! ' <<<"$output"; then
	echo "telegraf config check failed" >&2
	exit 1
fi
echo "telegraf config check passed"
