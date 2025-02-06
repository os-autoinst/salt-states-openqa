#!/bin/bash

[[ $1 == --help || $1 == -h ]] && \
echo "Prints the systemd unit names of openQA workers slots on the system

If slot numbers are specified explicitly, the unit names for those slots are
returned. Otherwise the unit names for the configured number of worker slots is
returned.

Usage: $0 [options] [slots numbers]…

Options:
 --masking       Print unit names relevant for masking and unmasking as well
 --starting      Print unit names relevant for starting as well
 --reload-only   Print only unit names relevant for reloading

Examples:
 systemctl restart \$($0)
 systemctl mask --now \$($0 --masking 20 21)" \
&& exit 0

# read CLI options
declare -A options
while [[ $1 =~ --(masking|starting|reload-only) ]]; do
    options[${BASH_REMATCH[1]}]=1; shift
done

# read slots from workers.ini (as written by salt-states-openqa) or use slots specified via CLI args
if [[ $# -lt 1 ]]; then
    slot_count=$(grep 'numofworkers: ' /etc/openqa/workers.ini | sed -e 's/.*: //')
    slots=($(seq 1 "$slot_count"))
else
    slots=("$@")
fi

# print names of units
declare -a units
for i in "${slots[@]}"; do
    [[ ${options[reload-only]} ]] || units+=("openqa-worker-auto-restart@$i".service)
    [[ ${options[masking]} ]] && units+=("openqa-reload-worker-auto-restart@$i".service)
    [[ ${options[masking]} || ${options[starting]} ]] && units+=("openqa-reload-worker-auto-restart@$i".path)
done
echo "${units[@]}"
