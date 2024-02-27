# Set accept_ra on all native linux bridges (non openvswitch) to allow SLAAC to work on these hosts

{% for brif in (salt['cmd.shell']('ip -o link show type bridge | cut -d : -f 2 | xargs -I{} echo {}').split('\n') | reject("eq", "")) %}
net.ipv6.conf.{{ brif }}.accept_ra:
  sysctl.present:
    - value: 2
{% endfor %}
