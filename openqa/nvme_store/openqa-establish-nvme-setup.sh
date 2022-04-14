#!/bin/bash
set -euo pipefail

echo 'Current mount points (printed for debugging purposes):'
mount

echo 'Present block devices (printed for debugging purposes):'
lsblk

# Create striped storage for openQA from all NVMe devices when / resides on
# another device or from a potential third NVMe partition when there is only a
# single NVMe device for the complete storage

# create RAID0, try again if mdadm ran into timeout (see poo#88191)
attempts=${RAID_CREATION_ATTEMPTS:-10}
busy_delay=${RAID_CREATION_BUSY_DELAY:-10}
for (( attempt=1; attempt <= "$attempts"; ++attempt )); do
    [[ $attempt -gt 1 ]] && echo "Trying RAID0 creation again after timeout (attempt $attempt of $attempts)"

    # ensure RAID is not already running (will fail if RAID is currently mounted)
    if [[ -e /dev/md/openqa ]]; then
        echo 'Stopping current RAID "/dev/md/openqa"'
        mdadm --stop /dev/md/openqa || echo "Unable to stop RAID (mdadm return code: $?)"
    fi

    # make arguments for mdadm invocation
    mdadm_args=(--create /dev/md/openqa --level=0 --force --assume-clean)
    if lsblk --noheadings | grep -q "raid" || lsblk --noheadings | grep -v nvme | grep "/$"; then
        echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme?n1
        mdadm_args+=(--raid-devices="$(ls /dev/nvme?n1 | wc -l)" --run /dev/nvme?n1)
    else
        echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme0n1p3
        mdadm_args+=(--raid-devices=1 --run /dev/nvme0n1p3)
    fi

    if ! mdadm "${mdadm_args[@]}" 2>&1 | tee /tmp/mdadm_output; then
        if grep --quiet 'Device or resource busy' /tmp/mdadm_output; then
            echo "Waiting $busy_delay seconds before trying again after failing due to busy device."
            sleep "$busy_delay"
            continue
        elif grep --quiet 'unexpected failure opening' /tmp/mdadm_output; then
            echo "Unexpected error opening device, waiting $busy_delay before trying again (as retrying usually helps)."
            sleep "$busy_delay"
            continue
        else
            echo 'Unable to create RAID, mdadm returned with non-zero code'
            exit 1
        fi
    fi
    grep --quiet 'timeout waiting for /dev/md/openqa' /tmp/mdadm_output || break
    echo "Waiting $busy_delay seconds before trying again after failing due to timeout."
    sleep "$busy_delay"
done

# Ensure device is correctly initialized but also spend a little time before
# trying to create a filesystem to prevent a "busy" error
echo 'Status for RAID0 "/dev/md/openqa"'
grep nvme /proc/mdstat
mdadm --detail --scan | grep openqa

echo 'Creating ext2 filesystem on RAID0 "/dev/md/openqa"'
/sbin/mkfs.ext2 -F /dev/md/openqa
