/etc/libvirt/hooks/qemu.d/setup-sut-firewall.sh:
  file.managed:
    - makedirs: true
    - source: salt://openqa/kvm_firewall/setup-sut-firewall.sh.template
    - template: jinja
    - mode: "0774"

xmlstarlet:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5
