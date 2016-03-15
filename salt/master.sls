saltmaster.packages:
  pkg.installed:
    - pkgs:
      - salt-master

git -C /srv/salt pull >/dev/null 2>&1:
  cron.present:
    - user: root
    - minute: '*/5'
