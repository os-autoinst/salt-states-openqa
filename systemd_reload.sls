{%- if not grains.get('noservices', False) %}
# only gets executed if other states require it via onchanges_in (e.g. drop-in config overrides)
systemd_daemon_reload:
  cmd.run:
    - name: systemctl daemon-reload
{% endif %}
