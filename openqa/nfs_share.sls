nfs-client:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

# Newer Os versions and in particular container environments might not have
# /etc/fstab so we ensure it does exist.
# Also see https://github.com/saltstack/salt/issues/14103#issuecomment-1652305681
/etc/fstab:
  file.managed:
    # avoid warning for omitting any kind of source by setting replace to false
    - replace: false

{%- if not grains.get('noservices', False) %}
{% set nfs_hostname = pillar['commonconf']['nfspath'].split(":", 1)[0] %}
{% set ipv4 = salt["dnsutil.A"](nfs_hostname) %}
{% set ipv6 = salt["dnsutil.AAAA"](nfs_hostname) %}
{% set ip_list = [] %}
{%- if ipv4 is list %}
{% do ip_list.extend(ipv4) %}
{%- endif %}
{%- if ipv6 is list %}
{% do ip_list.extend(ipv6) %}
{%- endif %}
# Define static dns entries in /etc/hosts for our nfs server to ensure
# reachability even in early boot steps.
static_nfs_hostname:
  host.present:
    - ip: {{ ip_list }}
    - names:
      - {{ nfs_hostname }}

# Ensure NFS share is mounted and setup on boot
# Additional options to prevent failed mount attempts after bootup. Remote
# filesystem mounts wait for network-online.target which apparently is not
# ensured by wicked to mean that the remote target is reachable
# https://progress.opensuse.org/issues/92302
/var/lib/openqa/share:
  mount.mounted:
    - device: {{ pillar['commonconf']['nfspath'] }}
    - fstype: nfs
    - opts: ro,noauto,nofail,retry=30,x-systemd.mount-timeout=30m,x-systemd.automount
    # according to https://docs.saltproject.io/en/latest/ref/states/all/salt.states.mount.html#salt.states.mount.mounted we need to specify "extra mount options/keys" that we need to specify to prevent constent remounting because these options would not show up in /proc/self/mountinfo
    - extra_mount_invisible_options:
      - noauto
      - x-systemd.automount
    - extra_mount_invisible_keys:
      - x-systemd.mount-timeout
    - require:
      - pkg: nfs-client
      - file: /etc/fstab
      - host: static_nfs_hostname
 {%- endif %}
