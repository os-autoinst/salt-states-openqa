{% for i in (0, 2, 3) %}

/etc/qemu-ifup-br{{ i }}:
  file.managed:
    - mode: 755
    - contents: |
        #!/bin/sh
        sudo brctl addif br{{ i }} $1
        sudo ip link set $1 up

/etc/qemu-ifdown-br{{ i }}:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/sh
        sudo brctl delif br{{ i }} $1
        sudo ip link delete $1

{% endfor %}

