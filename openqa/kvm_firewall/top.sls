/etc/libvirt/hooks/qemu.d/setup-sut-firewall.sh:
  file.managed:
    - makedirs: True
    - source: salt://openqa/kvm_firewall/setup-sut-firewall.sh.template
    - template: jinja
    - mode: "0774"

xmlstarlet:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
