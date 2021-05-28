# Workarounds for https://bugzilla.opensuse.org/show_bug.cgi?id=1181418
# Can be deleted if the corresponding bugreport is fixed.
# Please read the related commit message for more details.

/var/log/openvswitch:
  file.directory:
    - user: openvswitch
    - group: openvswitch
    - recurse:
        - user
        - group

/etc/logrotate.d/openvswitch:
  file.line:
    - after: "    su openvswitch openvswitch"
    - content: "    create openvswitch openvswitch"
    - mode: insert

/etc/sysconfig/openvswitch:
  file.replace:
    - pattern: '^(OVS_USER_ID.*)$'
    - repl: '#\1'
    - ignore_if_missing: True

/etc/openvswitch:
  file.directory:
    - user: openvswitch
    - group: openvswitch
    - recurse:
        - user
        - group

{%- if not grains.get('noservices', False) %}
{% for service in ('ovsdb-server.service', 'ovs-vswitchd.service', 'os-autoinst-openvswitch.service') %}
{{ service }}:
  service.running:
    - restart: True
    - watch:
      - file: /etc/sysconfig/openvswitch
      - file: /etc/openvswitch
{% endfor %}
{%- endif %}
