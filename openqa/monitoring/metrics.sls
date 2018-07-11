/usr/local/share/get-metrics:
  file.managed:
    - source: salt://openqa/monitoring/get-metrics
    - user: root
    - group: root
    - mode: 555
    - attrs: i

openqa_metrics:
  file.managed:
    - name: /etc/systemd/system/openqa-metrics.service
    - source: salt://openqa/monitoring/openqa-metrics.service
    - user: root
    - group: root
    - mode: 644
    - attrs: i
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: openqa-metrics

openqa_metrics_timer:
  file.managed:
    - name: /etc/systemd/system/openqa-metrics.timer
    - source: salt://openqa/monitoring/openqa-metrics.timer
    - user: root
    - group: root
    - mode: 644
    - attrs: i
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: openqa-metrics-timer

openqa_metrics_running:
  service.running:
    - name: openqa-metrics.timer
    - enable: True
    - watch:
      - module: openqa_metrics_timer
