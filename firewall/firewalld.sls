# Configure firewall: os-autoinst needs to upload logs to rather random ports and ovs needs configuration

firewalld.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - firewalld # For TAP support and for other good reasons

firewalld_config:
  file.replace:
    - name: /etc/firewalld/firewalld.conf
    - pattern: '^DefaultZone=.*$'
    - repl: 'DefaultZone=trusted'
    - append_if_not_found: True
    - require:
      - pkg: worker.packages

{%- if not grains.get('noservices', False) %}
# disable our own nftables
firewall:
   service.dead:
     - enable: False

firewalld:
   service.running:
     - enable: True
     - watch_any:
       - file: /etc/firewalld/firewalld.conf
{% if grains.get('host') in pillar.get('workerconf').keys() %}
       - file: /etc/firewalld/zones/trusted.xml
{% endif %}
{% endif %}

{% if grains.get('host') in pillar.get('workerconf').keys() %}
firewalld_zones:
  file.managed:
    - template: jinja
    - names:
      - /etc/firewalld/zones/trusted.xml:
        - source: salt://etc/firewalld/zones/trusted.xml

# ensures the bridge_iface and br1 are only present in our own zone if
# e.g. the installer put them into a different one
{%- set trusted_interfaces = [pillar['workerconf'][grains['host']]['bridge_iface'], "br1"] %}
{%- for interface in trusted_interfaces -%}
move_interface_permanent_{{ interface }}:
  cmd.run:
    - unless: test $(firewall-cmd --permanent --get-zone-of-interface={{ interface }}) == "trusted"
    - name: sed -i '/name="{{ interface }}"/d' /etc/firewalld/zones/*.xml; firewall-cmd --reload; firewall-cmd --zone=trusted --change-interface={{ interface }} --permanent
move_interface_runtime_{{ interface }}:
  cmd.run:
    - unless: test $(firewall-cmd --get-zone-of-interface={{ interface }}) == "trusted"
    - name: firewall-cmd --zone=trusted --change-interface={{ interface }}
{% endfor -%}
{% endif %}
