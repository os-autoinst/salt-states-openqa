workerconf:
  required_external_networks:
  - host: foo.bar

  available_webuis:
    webui.test:
      testpoolurl: rsync://webui.test/tests

  worker1.test:
    numofworkers: 1
    bridge_iface: eth0
    webuis:
      webui.test:
        key: foo
        secret: bar
    global:
      WORKER_CLASS: qemu_x86_64
    workers:
      1:
        TEST_SETTING: setting for slot 1
