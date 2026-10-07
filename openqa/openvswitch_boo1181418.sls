# Workarounds for https://bugzilla.opensuse.org/show_bug.cgi?id=1181418
# Can be deleted if the corresponding bugreport is fixed.
# Please read the related commit message for more details.

{%- set backend = grains.get('network_backend', 'wicked') %}
{%- set noservices = grains.get('noservices', False) %}
{%- if not noservices and backend == 'NetworkManager' %}
include:
  - openqa.openvswitch
{%- endif %}

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

{%- if not noservices %}
{% for service in ('ovsdb-server.service', 'ovs-vswitchd.service', 'os-autoinst-openvswitch.service') %}
{{ service }}:
  service.running:
    - watch:
      - file: /etc/sysconfig/openvswitch
      - file: /etc/openvswitch
   {%- if backend == 'NetworkManager' and service != 'os-autoinst-openvswitch.service' %}
    - onchanges_in:
      - cmd: restart_networkmanager_after_openvswitch
   {%- endif %}
{% endfor %}
{%- endif %}
