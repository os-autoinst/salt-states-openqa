include:
 - sudo

openssh:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://sshd/sshd_config

{%- if grains["host"] == "openqaw5-xen" %}
permitrootlogin:
  file.line:
    - name: /etc/ssh/sshd_config
    - mode: replace
    - match: PermitRootLogin without-password
    - content: PermitRootLogin yes

permitpasswordauth:
  file.line:
    - name: /etc/ssh/sshd_config
    - mode: replace
    - match: PasswordAuthentication no 
    - content: PasswordAuthentication yes 
{%- endif %}

{%- if not grains.get('noservices', False) %}
sshd:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ssh/sshd_config
{%- endif %}

AAAAC3NzaC1lZDI1NTE5AAAAINy2519eyXRQF1qexQhEEjuAtMrgpnndeTbQBm4VSzR8:
  ssh_auth.present:
    - user: root
    - enc: ssh-ed25519
    - comment: root@backup-vm

AAAAC3NzaC1lZDI1NTE5AAAAIODlqAE/HJh5EvjIioaHbfUY0JC6Rk5MK0FVM1hKBRmx:
  ssh_auth.present:
    - user: root
    - enc: ssh-ed25519
    - comment: root@storage.oqa.suse.de, backup OSD

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
