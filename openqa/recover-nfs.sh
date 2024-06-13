#!/bin/bash

function recover_mountpoint() {
  umount -l "$1"
  mount -a --target "$1"
}

# Step 1: Use df to find stale file handles
list=$(timeout --signal=KILL 5 df 2>&1 | grep 'Stale file handle' | awk '{print ""$2"" }' | tr -d \:)
for directory in $list
do
  recover_mountpoint "$directory"
done

# Step 2: Use terse stat output with a timeout and lsof in "non blocking mode" to find problems of the mountpoint
while read _ _ mount _; do
  read -t1 < <(stat -t "$mount") || lsof -b 2>/dev/null|grep -q "$mount" && recover_mountpoint "$mount";
done < <(mount -t nfs)
