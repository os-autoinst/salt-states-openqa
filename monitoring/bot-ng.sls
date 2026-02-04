/etc/telegraf/telegraf.d/bot-ng.conf:
  file.managed:
    - source: salt://monitoring/telegraf/bot-ng.conf
    - template: jinja
    - makedirs: true
