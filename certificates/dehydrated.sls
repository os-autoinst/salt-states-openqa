# dehydrated SSL management, needs dehydrated package which supplies
# dehydrated-postrun-hooks. At time of writing 2021-11-29 neither
# openSUSE Leap 15.2 nor openSUSE Leap 15.3 include that

dehydrated.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - dehydrated
      - dehydrated-{{grains.get('webserver', 'webserver-grain-not-set')}}
    - require:
      - webserver_grain

/etc/dehydrated/config.d/{{ pillar['dehydrated']['config_script'] }}:
  file.managed:
    - source: salt://etc/master/dehydrated/config.d/{{ pillar['dehydrated']['config_script'] }}
/etc/dehydrated/domains.txt:
  file.managed:
    - contents: {{ pillar['dehydrated']['hosts.txt'].get(grains['fqdn'], [grains['fqdn']]) | join("\n") }}

/etc/dehydrated/postrun-hooks.d/reload-webserver.sh:
  file.managed:
    - mode: 755
    - contents: |
        #!/bin/sh
        systemctl reload {{ grains.get('webserver', '') }}

/etc/systemd/system/dehydrated-postrun-hooks.service:
  file.managed:
    - source: salt://openqa/dehydrated-postrun-hooks.service

'dehydrated --register --accept-terms':
  cmd.run:
    - runas: dehydrated
    - unless: test -n "$(ls -A /etc/dehydrated/accounts/*/)"

{%- if not grains.get('noservices', False) %}
dehydrated-postrun-hooks:
  service.enabled

dehydrated.timer:
  service.running:
    - enable: True

# using cmd.run as the service is supposed to exit quickly so we can not use service.running
'systemctl start dehydrated':
  cmd.run:
    - onchanges:
      - file: /etc/dehydrated/config.d/{{ pillar['dehydrated']['config_script'] }}
      - file: /etc/dehydrated/domains.txt
    - require:
       - webserver_config
{%- endif %}
