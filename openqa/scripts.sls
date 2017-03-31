{% for machine, scripts in pillar.get('scripts', {}).items() %}
  {% for script, content in scripts.items() %}
   
    /etc/openqa/scripts/{{ machine }}_{{ script }}.sh:
      file.managed:
       - mode: 755
       - makedirs: True
       - contents:  |
          #!/bin/sh
  
          {{ content }}

  {% endfor %}
{% endfor %}

{% for i in (0, 2, 3) %}

    /etc/qemu-ifup-br{{ i }}:
      file.managed:
        - mode: 755
        - contents:  |
           #!/bin/sh
           
           sudo brctl addif br{{ i }} $1
           sudo ip link set $1 up
    
    /etc/qemu-ifdown-{{ i }}:
      file.managed:
        - user: root
        - group: root
        - mode: 755
        - contents:  |
          #!/bin/sh
          sudo brctl delif {{ i }} $1
          sudo ip link delete $i

{% endfor %}

