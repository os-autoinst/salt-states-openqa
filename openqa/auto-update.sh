#!/bin/bash -ex

zypper_patch() {
    ret=0
    zypper -n --no-refresh --non-interactive-include-reboot-patches patch --replacefiles --auto-agree-with-licenses --download-in-advance || ret=$?
    [[ $ret == 102 ]] && ret=0 # don't interpret exit code [102 - ZYPPER_EXIT_INF_REBOOT_NEEDED] as an error
    return $ret
}

zypper -n ref
for i in {1..2} ; do
    # 1st patch call will update zypp, 2nd will update the system
    if ! zypper_patch ; then
        # update patch locks
        echo "zypper patch failed - trying again with updated patch locks"
        # remove old patch locks
        zypper ll | grep 'AUTO-UPDATE CONFLICTING PATCH' | awk '{print $3}' | while read lock ; do
            zypper rl "$lock"
        done

        # regenerate patch locks for current package locks
        zypper ll | grep '|\spackage\s|' | awk '{print $3}' | while read pkg ; do
            echo "Checking for conflicting patches for $pkg"
            zypper --no-refresh se --conflicts-pkg "$pkg" | grep -P '^!\s.*?\|' | awk '{print $3}' | while read patch ; do
                zypper al -tpatch -m "AUTO-UPDATE CONFLICTING PATCH: patch would conflict with $pkg" "$patch"
            done
        done

        zypper_patch
    fi
done

needs-restarting --reboothint >/dev/null || (command -v rebootmgrctl >/dev/null && rebootmgrctl reboot ||:)
