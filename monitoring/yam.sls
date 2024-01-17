/etc/telegraf/telegraf.d/yam.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [[inputs.exec]]
          commands = [ "/etc/telegraf/scripts/backlogger/backlogger.py --output=influxdb /etc/telegraf/scripts/tools-yam-backlog/queries.yaml" ]
          environment = ["REDMINE_API_KEY={{ pillar['credentials']['redmine']['api_key'] }}"]
          interval = "4h"
          timeout = "5m"
          data_format = "influx"

yam:
  git.latest:
    - name: https://github.com/rakoenig/qe-yam-backlog-assistant.git
    - target: /etc/telegraf/scripts/tools-yam-backlog
    - depth: 1
    - rev: master
