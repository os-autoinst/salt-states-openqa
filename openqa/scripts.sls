https://gitlab.suse.de/openqa/scripts.git:
  git.cloned:
    - target: /opt/openqa-scripts

openqa_scripts_config:
  # allow deployment to checked out branch from
  # https://gitlab.suse.de/openqa/scripts/blob/master/.gitlab-ci.yml
  git.config_set:
    - name: receive.denyCurrentBranch
    - value: ignore
    - repo: /opt/openqa-scripts

{% for machine, scripts in pillar.get('scripts', {}).items() %}
  {% for script, content in scripts.items() %}
/etc/openqa/scripts/{{ machine }}_{{ script }}.sh:
  file.managed:
    - mode: 755
    - makedirs: True
    - contents: |
        #!/bin/sh
        {{ content }}

  {% endfor %}
{% endfor %}

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

