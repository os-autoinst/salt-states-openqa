# Make sure the journal is stored persistently, also on workers, e.g. to debug
# vanishing/stuck workers
/var/log/journal:
  file.directory:
    - makedirs: true

rsyslog:
  pkg.purged

syslog-service:
  pkg.purged
