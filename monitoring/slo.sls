/etc/telegraf/telegraf.d/slo.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [[inputs.exec]]
          commands = [ "/etc/telegraf/scripts/backlogger/backlogger.py --output=influxdb /etc/telegraf/scripts/tools-backlog/queries.yaml" ]
          environment = ["REDMINE_API_KEY={{ pillar['credentials']['redmine']['api_key'] }}"]
          interval = "1h"
          timeout = "10s"
          data_format = "influx"

backlogger:
  git.latest:
    - name: https://github.com/openSUSE/backlogger.git
    - target: /etc/telegraf/scripts/backlogger
    - depth: 1
    - rev: main

tools:
  git.latest:
    - name: https://github.com/os-autoinst/qa-tools-backlog-assistant.git
    - target: /etc/telegraf/scripts/tools-backlog
    - depth: 1
    - rev: master
