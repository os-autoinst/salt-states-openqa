#!/bin/bash
set -e

# Create striped storage for openQA from all NVMe devices when / resides on
# another device or from a potential third NVMe partition when there is only a
# single NVMe device for the complete storage

if [[ -e /dev/md/openqa ]]; then
    echo 'Stopping current RAID "/dev/md/openqa"'
    mdadm --stop /dev/md/openqa
fi
if lsblk --noheadings | grep -q "raid" || lsblk --noheadings | grep -v nvme | grep "/$"; then
    echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme?n1
    mdadm --create /dev/md/openqa --level=0 --force --raid-devices="$(ls /dev/nvme?n1 | wc -l)" --run /dev/nvme?n1
else
    echo 'Creating RAID0 "/dev/md/openqa" on:' /dev/nvme0n1p3
    mdadm --create /dev/md/openqa --level=0 --force --raid-devices=1 --run /dev/nvme0n1p3
fi

# Ensure device is correctly initialized but also spend a little time before
# trying to create a filesystem to prevent a "busy" error
echo 'Status for RAID0 "/dev/md/openqa"'
grep nvme /proc/mdstat
mdadm --detail --scan | grep openqa

echo 'Creating ext2 filesystem on RAID0 "/dev/md/openqa"'
/sbin/mkfs.ext2 -F /dev/md/openqa