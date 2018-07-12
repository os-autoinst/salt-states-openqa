/usr/local/share/get-metrics:
  file.managed:
    - source: salt://openqa/monitoring/get-metrics
    - user: root
    - group: root
    - mode: 555
    - attrs: i

/etc/systemd/system/openqa-metrics.service:
  file.managed:
    - template: jinja
    - source:
      - salt://openqa/monitoring/openqa-metrics.service
    - user: root
    - group: root
    - mode: 644
  module.run:
    - name: service.systemctl_reload

/etc/systemd/system/openqa-metrics.timer:
  file.managed:
    - source: salt://openqa/monitoring/openqa-metrics.timer
    - user: root
    - group: root
    - mode: 644
    - attrs: i

openqa_metrics_running:
  service.running:
    - name: openqa-metrics.timer
    - enable: True
