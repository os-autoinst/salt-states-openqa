kdump:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5

python3-augeas:
  pkg.installed:
    # python3 is now a capability provided by a minor version package
    - resolve_capabilities: True
    - refresh: False
    - retry:
        attempts: 5

/etc/default/grub:
  file.append:
    - text:
{%- for config_line in ['GRUB_CMDLINE_LINUX_DEFAULT', 'GRUB_CMDLINE_XEN_DEFAULT'] %}
      - '{{ config_line }} +=" crashkernel=210M"'
{%- endfor %}

update grub config with crashkernel setting:
  cmd.run:
    - name: 'grub2-mkconfig > /boot/grub2/grub.cfg'
    - onchanges:
      - file: /etc/default/grub
    - onlyif: grub2-probe /boot

/etc/systemd/system/check-for-kernel-crash.service:
  file.managed:
    - mode: "0644"
    - source: salt://openqa/check-for-kernel-crash.service

kdump-conf:
  augeas.change:
    - require:
      - pkg: python3-augeas
    - lens: Shellvars.lns
    - context: /files/etc/sysconfig/kdump
    - changes:
      - set KDUMP_SMTP_SERVER '"relay.suse.de"'
      - set KDUMP_NOTIFICATION_TO '"osd-admins@suse.de"'

{%- if not grains.get('noservices', False) %}
# as kdump needs reserved memory which is only made effective by a reboot we
# must not start the service but only enable it to be started on bootup
kdump-service:
  service.enabled:
    - name: kdump.service
    - watch:
      - augeas: kdump-conf

check-for-kernel-crash:
  service.enabled
{%- endif %}
