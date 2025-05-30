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
    - template: jinja
    - source: salt://postfix/sysconfig/postfix
    - require:
      - pkg: mailserver.packages

{%- if not grains.get('noservices', False) %}
"config.postfix":
    cmd.run:
      - onchanges:
        - file: /etc/sysconfig/mail
        - file: /etc/sysconfig/postfix

postfix:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - watch:
      - alias: root_mail_forward
      - file: /etc/sysconfig/mail
      - file: /etc/sysconfig/postfix
    - require:
      - pkg: mailserver.packages
{%- endif %}

root_mail_forward:
  alias.present:
    - name: root
    - target: osd-admins@suse.de, \root

/etc/systemd/system/kdump-notify.service.d/wait-for-postfix.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Unit]
        After=postfix.service
