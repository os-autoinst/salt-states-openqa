# monitor extra certificates which are not part of the certificates.dehydrated role
/etc/telegraf/telegraf.d/external_certificates.conf:
  file.managed:
    - template: jinja
    - source: salt://monitoring/telegraf/external_certificates.conf
    - user: root
    - group: root
    - mode: "0600"
    - makedirs: True
