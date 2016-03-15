/etc/ssh/sshd_config:
  file.managed:
    - source: salt://sshd/sshd_config

sshd:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ssh/sshd_config

{% for username, details in pillar.get('users', {}).items() %}
{{ username }}:

  user:
    - present
    - fullname: {{ details.get('fullname','') }}
    - name: {{ username }}
    - shell: /bin/bash
    - home: /home/{{ username }}

  {% if 'pub_ssh_keys' in details %}
  ssh_auth:
    - present
    - user: {{ username }}
    - names:
    {% for pub_ssh_key in details.get('pub_ssh_keys', []) %}
      - {{ pub_ssh_key }}
    {% endfor %}
    - require:
      - user: {{ username }}
  {% endif %}

  file.append:
    - name: /etc/sudoers
    - text: {{ details.get('name','') }} ALL=(ALL) NOPASSWD: ALL

{% endfor %}
