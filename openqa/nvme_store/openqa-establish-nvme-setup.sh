#!/bin/bash
set -euo pipefail

echo 'Current mount points (printed for debugging purposes):'
mount

echo 'Present block devices (printed for debugging purposes):'
lsblk

# Create striped storage for openQA from all NVMe devices when / resides on
# another device or from a potential third NVMe partition when there is only a
# single NVMe device for the complete storage

device=$(sed -n -e 's|openqa_store: ||p'  /etc/salt/grains)

# create RAID0, try again if mdadm ran into timeout (see poo#88191)
attempts=${RAID_CREATION_ATTEMPTS:-10}
busy_delay=${RAID_CREATION_BUSY_DELAY:-10}
for (( attempt=1; attempt <= "$attempts"; ++attempt )); do
    [[ $attempt -gt 1 ]] && echo "Trying RAID0 creation again after timeout (attempt $attempt of $attempts)"

    # ensure RAID is not already running (will fail if RAID is currently mounted)
    if [ -e /dev/md/*openqa ]; then
        echo 'Stopping current RAID "/dev/md/*openqa"'
        mdadm --stop /dev/md/*openqa || echo "Unable to stop RAID (mdadm return code: $?)"
    fi

    # find suitable NVMe device
    if [[ -z $device ]]; then
        # add all NVMe devices that are not the root device
        root_dev=$(findmnt --noheadings -o SOURCE /)
        if echo "$root_dev" | grep /dev/nvme; then # is the root device an NVMe?
            # filter root device from list of NVMe devices
            root_nvme=$(echo "$root_dev" | sed -r 's|(/dev/nvme.+n1)p.*|\1|g')
            shopt -s nullglob
            for nvme in /dev/nvme?n1; do [[ $nvme != "$root_nvme" ]] && device+=" $nvme" ; done
            shopt -u nullglob
        else
            # use all
            device=/dev/nvme?n1
        fi
    fi

    # fallback to using the 3rd partition on the first NVMe
    device=${device:-/dev/nvme0n1p3}

    # make arguments for mdadm invocation
    echo 'Creating RAID0 "/dev/md/openqa" on:' $device
    mdadm_args=(--create /dev/md/openqa --level=0 --force --assume-clean
                --raid-devices="$(echo $device | wc -w)" --run $device)

    if ! mdadm "${mdadm_args[@]}" 2>&1 | tee /tmp/mdadm_output; then
        if grep --quiet 'Device or resource busy' /tmp/mdadm_output; then
            echo "Waiting $busy_delay seconds before trying again after failing due to busy device."
            sleep "$busy_delay"
            continue
        elif grep --quiet 'Array name /dev/md/openqa is in use already' /tmp/mdadm_output; then
            echo "Waiting $busy_delay seconds before trying again after failing due to in-use device (maybe it came up just after checking to stop it before)."
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
cat /proc/mdstat
mdadm --detail --scan | grep openqa

echo 'Creating ext2 filesystem on RAID0 "/dev/md/openqa"'
/sbin/mkfs.ext2 -F /dev/md/openqa
