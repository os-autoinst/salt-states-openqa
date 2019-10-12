include:
 - sudo

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://sshd/sshd_config

{%- if not grains.get('noservices', False) %}
sshd:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ssh/sshd_config
{%- endif %}

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

  file.managed:
    - name: /etc/sudoers.d/{{ username }}
    - mode: 600
    - contents:
      - '{{ username }} ALL=(ALL) NOPASSWD: ALL'
    - require:
      - sudo

{% endfor %}

nagios_permissions:
  file.managed:
    - name: /etc/sudoers.d/nagios
    - mode: 600
    - contents:
      - 'nagios ALL=(ALL) NOPASSWD: /usr/sbin/zypp-refresh,/usr/bin/zypper ref,/usr/bin/zypper sl,/usr/bin/zypper --xmlout --non-interactive list-updates -t package -t patch'
    - require:
      - sudo
