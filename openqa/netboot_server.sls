netboot.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - dnsmasq
      - darkhttpd

/etc/sysconfig/darkhttpd:
  file.managed:
    - require:
      - pkg: netboot.packages
    - contents: |
        DARKHTTPD_PARAMS="/srv/tftpboot/ --port 80 --ipv6 --uid darkhttpd --gid darkhttpd --syslog"

/etc/dnsmasq.conf:
  file.managed:
    - require:
      - pkg: netboot.packages
    - contents: |
        local-service
        port=0
        enable-tftp
        tftp-root=/srv/tftpboot
        tftp-no-fail
        tftp-no-blocksize

{%- if not grains.get('noservices', False) %}
dnsmasq:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/sysconfig/darkhttpd
    - require:
      - pkg: netboot.packages

darkhttpd:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/dnsmasq.conf
    - require:
      - pkg: netboot.packages
{%- endif %}
