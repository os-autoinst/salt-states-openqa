include:
  - openqa.server

# create osc user with lingering, allow them to write to /var/lib/openqa/factory/other/fixed via nogroup
osc_user:
  user.present:
    - name: osc
    - groups:
      - users
      - nogroup
{%- if not grains.get('noservices', False) %}
enable_linger_osc:
  cmd.run:
    - name: loginctl enable-linger osc
    - creates: /var/lib/systemd/linger/osc
    - require:
      - user: osc_user
{%- endif %}
openqa_fixed_dir_permissions:
  file.directory:
    - name: /var/lib/openqa/factory/other/fixed
    - mode: '0775'
    - group: nogroup

# copy the systemd user units locally on the minion for use with osc user
osc_systemd_user_dir:
  file.directory:
    - name: /home/osc/.config/systemd/user
    - user: osc
    - group: osc
    - makedirs: True
    - require:
      - user: osc_user
copy_osc_systemd_units:
  cmd.run:
    - name: cp -vR --target-directory=/home/osc/.config/systemd/user/ /opt/os-autoinst-scripts/systemd/user/*
    - runas: osc
    - creates: /home/osc/.config/systemd/user/os-autoinst-scripts-update-suse-unsupported-cert.timer
    - require:
      - cmd: git-clone-os-autoinst-scripts
      - file: osc_systemd_user_dir

# configure osc credentials for user osc
osc_config_file:
  file.managed:
    - name: /home/osc/.config/osc/oscrc
    - user: osc
    - group: osc
    - mode: '0600'
    - makedirs: True
    - contents: |
        [general]
        apiurl=https://api.suse.de
        [https://api.suse.de]
        user={{ salt['pillar.get']('osc_credentials:isc_user', '') }}
        pass={{ salt['pillar.get']('osc_credentials:isc_pass', '') }}
    - require:
      - user: osc_user

{%- if not grains.get('noservices', False) %}
# enable and start the timer to update suse-unsupported.crt
reload_osc_systemd_daemon:
  cmd.run:
    - name: systemctl --machine=osc@.host --user daemon-reload
    - onchanges:
      - cmd: copy_osc_systemd_units
enable_start_osc_timer:
  cmd.run:
    - name: systemctl --machine=osc@.host --user enable --now os-autoinst-scripts-update-suse-unsupported-cert.timer
    - unless: systemctl --machine=osc@.host --user is-active os-autoinst-scripts-update-suse-unsupported-cert.timer
    - require:
      - cmd: enable_linger_osc
      - cmd: reload_osc_systemd_daemon
      - cmd: copy_osc_systemd_units
{%- endif %}
