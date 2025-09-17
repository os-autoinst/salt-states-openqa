nfs-client:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

{%- set srcpath = [] %}
{%- set mntpnt = [] %}
{%- set ip_hostname_dict = {} %}
{%- set nfs_hostnames = [] -%}

{%- if not grains.get('noservices', False) %}
{#- Refer https://gitlab.suse.de/openqa/salt-pillars-openqa/-/blob/master/openqa/commonconf.sls -#}
{%- if pillar['commonconf']['nfspath']['source'] != 'None' %}
{%- if pillar['commonconf']['nfspath']['source'] | length == pillar['commonconf']['nfspath']['mountpoint'] | length -%}
{%- if pillar['commonconf']['nfspath']['source'] is iterable and pillar['commonconf']['nfspath']['mountpoint'] is iterable %}
{%- for src, mnt in pillar['commonconf']['nfspath']['source'] | zip(pillar['commonconf']['nfspath']['mountpoint']) %}
{%- do nfs_hostnames.append(src.split(":", 1)[0]) %}
{%- do srcpath.append(src) %}
{%- do mntpnt.append(mnt) %}
{%- for hostname in nfs_hostnames %}
{%- set ip_addr = salt["dnsutil.A"](hostname) %}
{%- do ip_addr.extend(salt["dnsutil.AAAA"](hostname)) %}
{%- do ip_hostname_dict.update({hostname: ip_addr})  %}
{%- endfor %}
{%- endfor %}

# Define static dns entries in /etc/hosts for our nfs server to ensure
# reachability even in early boot steps.
{% for hostname, ip in ip_hostname_dict.items() %}
static_nfs_hostname_{{ hostname.split(".", 1)[0] }}:
  host.present:
    - ip: {{ ip }}
    - names: {{ [hostname] }}
{% endfor %}

{%- if mntpnt is iterable and srcpath is iterable %}
# If automount suspended the mount, we only have a "systemd-1 type autofs"-
# mount. This causes salt to assume the (correct) mount is gone and remount
# it. If the mount was recently accessed, /proc/self/mountinfo contains the
# correct entry and salt moves on. So here we just quickly wake up the
# automounter to "prepare" the system for the `mount.mounted`-state later.
{%- for m, s in mntpnt | zip(srcpath) %}
wakeup_automount_{{ s.split(".", 1)[0] }}:
  cmd.run:
    - names:
      - ls -d {{ m }}/.
    - unless: bash -c 'mount | grep "{{ m }}.*nfs"'
{% endfor %}
{%- endif -%}

{% if mntpnt is iterable and srcpath is iterable %}
# Ensure NFS share is mounted and setup on boot
# Additional options to prevent failed mount attempts after bootup. Remote
# filesystem mounts wait for network-online.target which apparently is not
# ensured by wicked to mean that the remote target is reachable
# https://progress.opensuse.org/issues/92302
{%- for m, s in mntpnt | zip(srcpath) %}
{{ m }}:
  mount.mounted:
    - device: {{ s }}
    - fstype: nfs
    - opts: ro,nofail,retry=30,x-systemd.mount-timeout=30m,x-systemd.automount,nolock
    # according to https://docs.saltproject.io/en/latest/ref/states/all/salt.states.mount.html#salt.states.mount.mounted we need to specify "extra mount options/keys" that we need to specify to prevent constent remounting because these options would not show up in /proc/self/mountinfo
    - extra_mount_invisible_options:
      - noauto
      - x-systemd.automount
    - extra_mount_invisible_keys:
      - x-systemd.mount-timeout
    - require:
      - pkg: nfs-client
      - file: /etc/fstab
      - host: static_nfs_hostname_{{ s.split(".", 1)[0] }}
{% endfor -%}
{%- endif %}
{% endif -%}

/etc/systemd/system/automount-restarter@.service:
  file.managed:
    - source: salt://openqa/nfs-automount-restarter.conf
    - makedirs: True

/etc/systemd/system/var-lib-openqa-share.automount.d/restart-on-failure.conf:
  file.managed:
    - source: salt://openqa/nfs-automount-restart-on-failure.conf
    - makedirs: True
{%- else %}
display_error_message:
  module.run:
    - name: log.error
    - message: path and mountpoint in salt-pillars-openqa/openqa/commonconf.sls must have equal number of elements
{%- endif %}
{%- endif %}
{%- endif %}
