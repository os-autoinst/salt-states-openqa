/etc/telegraf/telegraf.d/yam.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [agent]
          interval = "10m"
          round_interval = true
          metric_batch_size = 1000
          metric_buffer_limit = 10000
          collection_jitter = "0s"
          flush_interval = "10m"
          flush_jitter = "0s"
          precision = ""
          hostname = ""
          omit_hostname = false
        [[inputs.exec]]
          commands = [ "/etc/telegraf/scripts/backlogger/backlogger.py --output=influxdb /etc/telegraf/scripts/tools-yam-backlog/queries.yaml" ]
          environment = ["REDMINE_API_KEY={{ pillar['credentials']['redmine']['yam_api_key'] }}"]
          interval = "4h"
          timeout = "5m"
          data_format = "influx"
        [[inputs.exec]]
          commands = ["/etc/telegraf/scripts/tools-yam-git-trees/git_trees.py -o os-autoinst -r os-autoinst-distri-opensuse -p schedule/yam/ -t yaml -m qe_yam_schedule_yaml"]
          timeout = "60s"
          interval = "4h"
          data_format = "influx"


yam:
  git.latest:
    - name: https://github.com/rakoenig/qe-yam-backlog-assistant.git
    - target: /etc/telegraf/scripts/tools-yam-backlog
    - depth: 1
    - rev: master

trees:
  git.latest:
    - name: https://github.com/manfredi/telegraf-git-trees.git
    - target: /etc/telegraf/scripts/tools-yam-git-trees
    - depth: 1
    - rev: main
