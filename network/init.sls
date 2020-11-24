/etc/hostname:
  file.managed:
    - contents: {{ grains['host'] }}
