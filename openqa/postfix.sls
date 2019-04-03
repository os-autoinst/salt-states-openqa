postfix:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - watch:
      - module: configure_relay

configure_relay:
  module.run:
    - name: postfix.set_main
    - key: relayhost
    - value: relay.suse.de
    - name: postfix.set_main
    - key: myhostname
    - value: openqa.suse.de
