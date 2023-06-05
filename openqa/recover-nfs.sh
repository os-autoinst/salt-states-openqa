#!/bin/sh
list=$(df 2>&1 | grep 'Stale file handle' | awk '{print ""$2"" }' | tr -d \:)
for directory in $list
do
  umount -l "$directory"
  mount -a
done
