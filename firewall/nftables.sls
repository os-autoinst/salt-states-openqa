# Configure firewall: os-autoinst needs to upload logs to rather random ports and ovs needs configuration

nftables.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - nftables

nftables_config:
  file.managed:
    - template: jinja
    - names:
      - /etc/firewall.nft:
        - source: salt://etc/firewall.nft
      - /etc/systemd/system/firewall.service:
        - source: salt://etc/systemd/system/firewall.service

{%- if not grains.get('noservices', False) %}
firewalld:
   service.dead:
     - enable: False
nftables:
  service.running:
    - enable: True
    - watch_any:
      - file: /etc/firewall.nft
    - require:
      - pkg: nftables.packages
{%- endif %}
