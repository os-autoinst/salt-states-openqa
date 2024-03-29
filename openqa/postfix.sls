{%- if not grains.get('noservices', False) %}
postfix:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - watch:
      - module: configure_relay
      - alias: root_mail_forward
      - file: /etc/sysconfig/mail
      - file: /etc/sysconfig/postfix
{%- endif %}

configure_relay:
  module.run:
    - name: postfix.set_main
    - key: relayhost
    - value: relay.suse.de
    - name: postfix.set_main
    - key: myhostname
    - value: {{ grains['fqdn'] }}

root_mail_forward:
  alias.present:
    - name: root
    - target: osd-admins@suse.de, \root
