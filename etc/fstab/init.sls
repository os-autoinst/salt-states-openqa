# Newer Os versions and in particular container environments might not have
# /etc/fstab so we ensure it does exist.
# Also see https://github.com/saltstack/salt/issues/14103#issuecomment-1652305681
/etc/fstab:
  file.managed:
    # avoid warning for omitting any kind of source by setting replace to false
    - replace: false
