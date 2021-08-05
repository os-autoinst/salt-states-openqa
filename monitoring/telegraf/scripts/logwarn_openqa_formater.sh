#!/bin/bash

# Exits with 0 if nothing to return
results=$(/opt/openqa-logwarn/logwarn_openqa) && exit 0

hostname=$(hostname -f)
[[ $hostname ]] || hostname=$(hostname)

echo $results | while read line; do echo logwarn_openqa,machine="${hostname}" message="${line}"; done