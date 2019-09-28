# Make sure the journal is stored persistently, also on workers, e.g. to debug
# vanishing/stuck workers
/var/log/journal:
  file.directory:
    - makedirs: True
