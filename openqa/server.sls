include:
 - openqa.repos
 - openqa.journal
 - logrotate

server.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
      - openQA
      - apache2
      - nginx
      - perl-Mojo-RabbitMQ-Client
      - perl-IPC-System-Simple
      - vsftpd
      - samba
      - postfix
      - cron
      - os-autoinst-scripts-deps  # for https://github.com/os-autoinst/os-autoinst-scripts
      - rsync  # for rsyncd

osd_fstab:
  file.managed:
    - name: /etc/fstab
    - source: salt://etc/fstab/osd_fstab
    - user: root
    - group: root

{%- if not grains.get('noservices', False) %}
'mount -a':
  cmd.run:
    - onchanges:
      - file: /etc/fstab
{%- endif %}

/etc/motd:
  file.managed:
    - contents: |
        This host runs the production openQA instance
        {{ grains.get('primary_webui_domain', grains.get('fqdn')) }}
        and is managed by
        https://gitlab.suse.de/openqa/salt-states-openqa.

        Be careful with manual administrative actions!


/etc/openqa/openqa.ini.d:
  file.directory:
    - user: geekotest

/etc/openqa/openqa.ini.d/openqa-salt.ini:
  file.managed:
    - source: salt://openqa/openqa-salt.ini
    - template: jinja
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/systemd/system/openqa-webui.service.d/10-unit-ordering.conf:
  file.managed:
    - mode: "0644"
    - source: salt://openqa/openqa-webui-unit-ordering.conf
    - makedirs: true

/etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf:
  file.managed:
    - name: /etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf
    - mode: "0644"
    - source: salt://openqa/openqa-hook-timeout.conf
    - makedirs: true
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
openqa-webui:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/openqa/openqa.ini.d/openqa-salt.ini

openqa-gru:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf
      - file: /etc/openqa/openqa.ini.d/openqa-salt.ini
{%- endif %}

/etc/apache2/conf.d/server-status.conf:
  file.managed:
    - source: salt://apache2/conf.d/server-status.conf
    - user: root
    - group: root
    - require:
      - pkg: server.packages

/etc/apache2/vhosts.d/openqa.conf:
  file.managed:
    - source: salt://apache2/vhosts.d/openqa.conf
    - template: jinja
    - user: root
    - group: root
    - require:
      - pkg: server.packages

webserver_grain:
  grains.present:
    - name: webserver
    - value: nginx

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/nginx.conf
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/nginx/vhosts.d/openqa.conf:
  file.managed:
    - source: salt://nginx/openqa.conf
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/nginx/vhosts.d/openqa-locations.inc:
  file.managed:
    - source: salt://nginx/openqa-locations.inc
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/nginx/conf.d/dehydrated.inc:
  file.managed:
    - source: salt://nginx/dehydrated.inc
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/nginx/conf.d/openqa-asset-config.inc:
  file.managed:
    - source: salt://nginx/openqa-asset-config.inc
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

/etc/nginx/vhosts.d/openqa-external-locations.inc:
  file.managed:
    - template: jinja
    - source: salt://nginx/openqa-external-locations.inc
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

# ext_pillar is not available with master-less mode so using "noservices"
# check as workaround to disable the following in our test environment
{%- if not grains.get('noservices', False) %}
/etc/apache2/vhosts.d/openqa-ssl.conf:
  file.keyvalue:
    - key_values:
        SSLCertificateFile: /etc/dehydrated/certs/{{ grains['fqdn'] }}/cert.pem
        SSLCertificateKeyFile: /etc/dehydrated/certs/{{ grains['fqdn'] }}/privkey.pem
        SSLCertificateChainFile: /etc/dehydrated/certs/{{ grains['fqdn'] }}/fullchain.pem
    - separator: ' '
    - uncomment: '#'

# ssh key files and config for needle pushing
# https://progress.opensuse.org/issues/67804
# Generated with
# ``ssh-keygen -t ed25519 -N '' -C 'geekotest@openqa.suse.de, openqa-pusher needle pushing to gitlab' -f id_ed25519.gitlab`
openqa_user_ssh:
  file.managed:
    - mode: "0644"
    - user: geekotest
    - group: nogroup
    - makedirs: True
    - names:
      - /var/lib/openqa/.ssh/id_ed25519.gitlab:
        - mode: "0600"
        - contents_pillar: id_ed25519.gitlab
      - /var/lib/openqa/.ssh/id_ed25519.gitlab.pub:
        - contents_pillar: id_ed25519.gitlab.pub
      - /var/lib/openqa/.ssh/config:
        - contents: |
            Host gitlab.suse.de
              User gitlab
              IdentityFile ~/.ssh/id_ed25519.gitlab
              IdentitiesOnly yes

{%- endif %}

# this relies on presence of devices and mounted partitions which are only
# available in a real system and also when we have "services" so we must
# exclude it when we are without
{%- if not grains.get('noservices', False) %}
/space-slow/archive:
  file.directory:
    - user: geekotest
    - require:
      - file: /etc/fstab

# requires the mount point as defined in "fstab"
/var/lib/openqa/archive/testresults:
  file.directory:
    - user: geekotest
{%- endif %}

/etc/telegraf/telegraf.d/telegraf-webui.conf:
  file.managed:
    - template: jinja
    - source: salt://monitoring/telegraf/telegraf-webui.conf
    - user: root
    - group: root
    - mode: "0600"
    - makedirs: True
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
telegraf_sql_queries:
  postgres_user.present:
    - name: telegraf
    - login: True

{% for table in ['jobs', 'job_groups', 'job_group_parents', 'job_dependencies', 'workers'] %}
telegraf_db_{{ table }}:
  postgres_privileges.present:
    - name: telegraf
    - object_name: {{ table }}
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa
{% endfor %}

readonly_db_access:
  postgres_user.present:
    - name: openqa
    - password: openqa

{% for table in ['jobs', 'job_settings', 'job_modules', 'job_dependencies', 'job_groups', 'job_group_parents', 'workers', 'audit_events'] %}
readonly_db_access_{{ table }}:
  postgres_privileges.present:
    - name: openqa
    - object_name: {{ table }}
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa
{% endfor %}

# allow access to postgres database from outside so far this does not ensure
# that the configuration becomes effective which needs a server restart
postgresql-listen_address:
  file.replace:
    - name: /srv/PSQL/data/postgresql.conf
    - pattern: "^#?(listen_addresses = ')[^']*('.*$)"
    - repl: '\1*\2'

postgresql-work_mem:
  file.replace:
    - name: /srv/PSQL/data/postgresql.conf
    - pattern: "^#?(work_mem =)[^B]*(.*$)"
    - repl: '\1 64M\2'

/srv/PSQL/data/pg_hba.conf:
  file.append:
    - text: |
        host    all             openqa          0.0.0.0/0               md5
        host    all             openqa          ::/0                    md5

postgresql.service:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /srv/PSQL/data/postgresql.conf
      - file: /srv/PSQL/data/pg_hba.conf
{%- endif %}

/etc/vsftpd.conf:
  file.managed:
    - source: salt://vsftpd/vsftpd.conf
    - user: root
    - group: root
    - mode: "0600"
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
vsftpd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/vsftpd.conf
{%- endif %}

{%- if not grains.get('noservices', False) %}
apache2:
  service.dead:
    - enable: False
    - watch:
      - file: /etc/apache2/vhosts.d/openqa.conf
{%- endif %}

{%- if not grains.get('noservices', False) %}
webserver_running:
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - file: /etc/nginx/vhosts.d/openqa.conf
      - file: /etc/nginx/vhosts.d/openqa-locations.inc
      - file: /etc/nginx/conf.d/dehydrated.inc
      - file: /etc/nginx/conf.d/openqa-asset-config.inc
      - file: /etc/nginx/nginx.conf

{%- endif %}

{%- if not grains.get('noservices', False) %}
salt-master.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/salt/master
{%- endif %}

/opt/git-sha-verify/:
  file.directory:
    - user: geekotest

# workaround for salt not being able to find git in test environment
gitconfig:
  git.config_unset:
    - name: foo
    - global: True
    - all: False

# workaround for git.cloned not being able to clone into existing directory
# owned by correct user
# https://github.com/saltstack/salt/issues/55926
'git clone https://gitlab.suse.de/qe/git-sha-verify /opt/git-sha-verify/':
  cmd.run:
    - runas: geekotest
    - creates: /opt/git-sha-verify/.git/

/opt/os-autoinst-scripts/:
  file.directory:
    - user: geekotest

# used by /opt/git-sha-verify/checkout-latest-signed-commit
/var/lib/openqa/.gnupg/:
  file.directory:
    - user: geekotest
    - mode: '0700'

# workaround for git.cloned not being able to clone into existing directory
# owned by correct user
# https://github.com/saltstack/salt/issues/55926
git-clone-os-autoinst-scripts:
  cmd.run:
    - name: /opt/git-sha-verify/checkout-latest-signed-commit /opt/os-autoinst-scripts/ https://github.com/os-autoinst/os-autoinst-scripts.git
    - creates: /opt/os-autoinst-scripts/.git/
    - runas: geekotest

# Reference: https://progress.opensuse.org/issues/191449
/etc/systemd/system/update-os-autoinst-scripts.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Update os-autoinst-scripts git repository
        [Service]
        Type=exec
        User=geekotest
        WorkingDirectory=/opt
        ExecStart=/bin/bash -lc '/opt/git-sha-verify/checkout-latest-signed-commit /opt/os-autoinst-scripts/ https://github.com/os-autoinst/os-autoinst-scripts.git || { echo -e "To: osd-admins@suse.de\nFrom: root <root@$(hostname)>\nSubject: update-os-autoinst-scripts.service failed\n\nSee journalctl -u update-os-autoinst-scripts.service -b\n" | sendmail -t }'

/etc/systemd/system/update-os-autoinst-scripts.timer:
  file.managed:
    - contents: |
        [Unit]
        Description=Update os-autoinst-scripts git repository
        [Timer]
        OnUnitInactiveSec=5min
        Persistent=True
        [Install]
        WantedBy=timers.target

{%- if not grains.get('noservices', False) %}
update-os-autoinst-scripts.timer:
  service.running:
    - enable: True

/etc/systemd/system/update-git-sha-verify.timer:
  file.managed:
    - contents: |
        [Unit]
        Description=Daily update of git-sha-verify
        [Timer]
        OnCalendar=00:42
        Persistent=true
        [Install]
        WantedBy=timers.target

/etc/systemd/system/update-git-sha-verify.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Update git-sha-verify
        [Service]
        Type=exec
        User=geekotest
        ExecStart=/usr/bin/git -C /opt/git-sha-verify/ pull -q --rebase

update-git-sha-verify.timer:
  service.running:
    - enable: True

cron.service:
  service.running:
    - enable: True
{%- endif %}

/etc/systemd/journald.conf.d/journal_size.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [Journal]
        SystemMaxUse=80G
        SystemKeepFree=16G
        SystemMaxFileSize=1G
        SystemMaxFiles=200

/etc/systemd/system/systemd-journal-flush.service.d/storage.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Unit]
        RequiresMountsFor=/srv

# Explicitly mention our required mount points to avoid a non-booting machine
# See https://progress.opensuse.org/issues/162356 for details
/etc/systemd/system/openqa-webui.service.d/storage.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Unit]
        RequiresMountsFor=/var/lib/openqa /var/lib/openqa/archive /var/lib/openqa/share /var/lib/openqa/share/factory/hdd/fixed /var/lib/openqa/share/factory/iso/fixed

/etc/systemd/system/auditd.service.d/storage.conf:
  file.managed:
    - mode: "0644"
    - makedirs: true
    - contents: |
        [Unit]
        RequiresMountsFor=/srv

/etc/rsyncd.conf:
  file.managed:
    - source: salt://rsyncd/rsyncd.conf
    - user: root
    - group: root
    - mode: "0644"
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
rsyncd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/rsyncd.conf

openqa-enqueue-git-auto-update.timer:
  service.running:
    - enable: True

openqa-dump-db.timer:
  service.running:
    - enable: True

{% for type in ['service', 'timer'] %}
# Prevent server unresponsiveness due to TRIM which is also debatable anyway
# on virtual machines
# https://progress.opensuse.org/issues/164427
fstrim.{{ type }}:
  service.dead:
    - enable: False
{% endfor %}
{%- endif %}

# Avoiding unintended connection failures with SO_REUSEPORT, see
# https://progress.opensuse.org/issues/181736#note-17
net.ipv4.tcp_migrate_req:
  sysctl.present:
    - value: 1
