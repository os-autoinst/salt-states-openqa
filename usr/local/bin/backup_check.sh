#!/bin/bash

BDIR="/storage/rsnapshot"

declare -a CHECK_HOSTS=(
        "localhost"
        "openqa.suse.de"
        "openqa.opensuse.org"
        "jenkins.qa.suse.de"
        "openqa-monitor.qa.suse.de"
        "s.qa.suse.de"
)

exitcode=0

for b in alpha beta ; do
        for h in "${CHECK_HOSTS[@]}" ; do
                bloc="$BDIR/$b.0/$h"
                if [[ ! -d "$bloc" ]] ; then
                        echo "'$bloc' does not exist!"
                        exitcode=1
                fi
        done
done

exit $exitcode
