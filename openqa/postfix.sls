mailserver.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - postfix
      - mailx

/etc/sysconfig/mail:
  file.managed:
    - source: salt://postfix/sysconfig/mail
    - require:
      - pkg: mailserver.packages

/etc/sysconfig/postfix:
  file.managed:
    - source: salt://postfix/sysconfig/postfix
    - require:
      - pkg: mailserver.packages

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
    - require:
      - pkg: mailserver.packages
{%- endif %}

{%- if salt['pkg.version']('postfix') %}
configure_relayhost:
  module.run:
    - postfix.set_main:
      - key: relayhost
      - value: relay.suse.de

configure_myhost:
  module.run:
    - postfix.set_main:
      - key: myhostname
      - value: {{ grains['fqdn'] }}
{%- endif %}

root_mail_forward:
  alias.present:
    - name: root
    - target: osd-admins@suse.de, \root
