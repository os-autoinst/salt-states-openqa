# The default of 256 connections is not enough on our workers as we run a lot of services.
# This can result in other services failing randomly as described in:
# https://progress.opensuse.org/issues/88225#note-2

/etc/dbus-1/system.d/system-local.conf:
  file.managed:
    - contents:
      - '<busconfig><limit name="max_connections_per_user">512</limit></busconfig>'
