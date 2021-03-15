#!/bin/bash
set -e

echo 'Current mount points (printed for debugging purposes):'
mount

echo 'Present block devices (printed for debugging purposes):'
lsblk

# Create striped storage for openQA from all NVMe devices when / resides on
# another device or from a potential third NVMe partition when there is only a
# single NVMe device for the complete storage

# make arguments for mdadm invocation
mdadm_args=(--create /dev/md/openqa --level=0 --force)
if lsblk --noheadings | grep -q "raid" || lsblk --noheadings | grep -v nvme | grep "/$"; then
    echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme?n1
    mdadm_args+=(--raid-devices="$(ls /dev/nvme?n1 | wc -l)" --run /dev/nvme?n1)
else
    echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme0n1p3
    mdadm_args+=(--raid-devices=1 --run /dev/nvme0n1p3)
fi

# create RAID0, try again if mdadm ran into timeout (see poo#88191)
attempts=${RAID_CREATION_ATTEMPTS:-4}
for (( attempt=1; attempt <= "$attempts"; ++attempt )); do
    [[ $attempt -gt 1 ]] && echo "Trying RAID0 creation again after timeout (attempt $attempt of $attempts)"

    # ensure RAID is not already running (will fail if RAID is currently mounted)
    if [[ -e /dev/md/openqa ]]; then
        echo 'Stopping current RAID "/dev/md/openqa"'
        mdadm --stop /dev/md/openqa
    fi

    mdadm_output=$(mdadm "${mdadm_args[@]}" 2>&1 | tee /dev/stderr)
    [[ $mdadm_output =~ 'timeout waiting for /dev/md/openqa' ]] || break
done

# Ensure device is correctly initialized but also spend a little time before
# trying to create a filesystem to prevent a "busy" error
echo 'Status for RAID0 "/dev/md/openqa"'
grep nvme /proc/mdstat
mdadm --detail --scan | grep openqa

echo 'Creating ext2 filesystem on RAID0 "/dev/md/openqa"'
/sbin/mkfs.ext2 -F /dev/md/openqa