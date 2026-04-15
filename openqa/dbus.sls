# The default of 256 connections is not enough on our workers as we run a lot of services.
# This can result in other services failing randomly as described in:
# https://progress.opensuse.org/issues/88225#note-2

dbus-limit-creation:
  file.managed:
    - name: /etc/dbus-1/system.d/system-local.conf
      contents:
        - '<busconfig><limit name="max_connections_per_user">512</limit></busconfig>'
      unless: &limit-check
        - fun: file.grep
          args:
            - /usr/share/dbus-1/system.d/
            - max_
            - '-r'

# Some packages like e.g. NetworkManager deploy own limits we do not know but are certainly
# more precise then our generic limit so we never deploy or remove it again if we detect such files.
dbus-limit-removal:
  file.absent:
    - name: /etc/dbus-1/system.d/system-local.conf
      onlyif: *limit-check
