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
      - os-autoinst-scripts-deps  # for https://github.com/os-autoinst/scripts
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

/etc/openqa/openqa.ini:
  ini.options_present:
    - sections:
        global:
          plugins: AMQP ObsRsync
          branding: {{ pillar['server']['branding'] }}
          scm: git
          download_domains: {{ pillar['server']['download_domains'] }}
          recognized_referers: {{ pillar['server']['recognized_referers'] }}
          max_rss_limit: 250000
          service_port_delta: 0
          access_control_allow_origin_header: http://container-dashboard.qe.suse.de
          # Workaround for missing uploads due to "timestamp mismatch", see https://progress.opensuse.org/issues/164296
          auto_clone_regex: '^(cache failure: |terminated prematurely: |api failure: Failed to register .* 503|backend died: .*VNC.*(timeout|timed out|refused)|QEMU terminated: Failed to allocate KVM HPT of order 25.* Cannot allocate memory|api failure: 403 response: timestamp mismatch.*)'
          # Higher value needed due to slow processing of api requests
          # https://progress.opensuse.org/issues/162038
          api_hmac_time_tolerance: 600
        auth:
          require_for_assets: 1
        amqp:
          url: {{ pillar['server']['amqp_url'] }}
          topic_prefix: suse
        logging:
          level: debug
        scm git:
          update_remote: 'origin'
          update_branch: 'origin/master'
          do_push: 'yes'
        openid:
          httpsonly: 1
        archiving:
          archive_preserved_important_jobs: 1
        cleanup:
          concurrent: 1
        audit:
          blocklist: 'job_grab job_done'
        audit/storage_duration:
          startup: 180
          jobgroup: 712
          jobtemplate: 712
          table: 712
          iso: 180
          user: 180
          asset: 90
          needle: 90
          other: 90
        assets/storage_duration:
          CURRENT: 10
        default_group_limits:
          asset_size_limit: 5
          log_storage_duration: 10
          important_log_storage_duration: 90
          result_storage_duration: 21
          important_result_storage_duration: 0
        no_group_limits:
          log_storage_duration: 5
          important_log_storage_duration: 25
          result_storage_duration: 15
          important_result_storage_duration: 50
        misc_limits:
          untracked_assets_storage_duration: 4
          result_cleanup_max_free_percentage: 20
          asset_cleanup_max_free_percentage: 20
          max_online_workers: 960
          worker_limit_retry_delay: 30
        obs_rsync:
          home: /opt/openqa-trigger-from-ibs
          project_status_url: https://api.suse.de/build/%%PROJECT/_result
          username: openqa-obs-bot
          ssh_key_file: /var/lib/openqa/.ssh/id_ed25519
        scheduler:
          max_job_scheduled_time: 7
          # See https://progress.opensuse.org/issues/134927 and
          # https://progress.opensuse.org/issues/160478
          # for value selection
          max_running_jobs: 330
        job_settings_ui:
          keys_to_render_as_links: YAML_SCHEDULE,YAML_SCHEDULE_DEFAULT,YAML_TEST_DATA,AUTOYAST,AGAMA_AUTO
        hooks:
          # Some groups excluded that have too many expected failing jobs or special review workflows
          # BCI tests disabled: poo#134915
          job_done_hook_failed: env enable_force_result=true email_unreviewed=true from_email=openqa-review@suse.de notification_address=discuss-openqa-auto-r-aaaagmhuypu2hq2kmzgovutmqm@suse.slack.com host=openqa.suse.de exclude_name_regex='.*(SAPHanaSR|saptune).*' exclude_group_regex='.*(Development|Public Cloud|Released|Others|Kernel|Virtualization|BCI).*' grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-and-investigate-hook
          job_done_hook_incomplete: env enable_force_result=true email_unreviewed=true from_email=openqa-review@suse.de notification_address=discuss-openqa-auto-r-aaaagmhuypu2hq2kmzgovutmqm@suse.slack.com host=openqa.suse.de grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-hook
          job_done_hook_timeout_exceeded: env email_unreviewed=true from_email=openqa-review@suse.de notification_address=discuss-openqa-auto-r-aaaagmhuypu2hq2kmzgovutmqm@suse.slack.com host=openqa.suse.de grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-hook
          job_done_hook: env host=openqa.suse.de email_unreviewed=true exclude_group_regex='.*(Development|Public Cloud|Released|Others|Kernel|Virtualization|Containers|BCI).*' grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-and-investigate-hook
        influxdb:
          ignored_failed_minion_jobs: obs_rsync_run obs_rsync_update_builds_text
    - require:
      - pkg: server.packages

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
      - ini: /etc/openqa/openqa.ini

openqa-gru:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf
      - ini: /etc/openqa/openqa.ini
{%- endif %}

/etc/openqa/database.ini:
  ini.options_present:
    - sections:
       production:
         dsn: dbi:Pg:dbname=openqa
         user: geekotest
    - require:
      - pkg: server.packages

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
{%- endif %}

{%- if not grains.get('noservices', False) %}
salt-master.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/salt/master
{%- endif %}

/etc/sysconfig/mail:
  file.managed:
    - source: salt://postfix/sysconfig/mail
    - require:
      - pkg: server.packages

/etc/sysconfig/postfix:
  file.managed:
    - source: salt://postfix/sysconfig/postfix

/opt/os-autoinst-scripts/:
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
git-clone-os-autoinst-scripts:
  cmd.run:
    - name: git clone https://github.com/os-autoinst/scripts.git /opt/os-autoinst-scripts/
    - creates: /opt/os-autoinst-scripts/.git/
    - runas: geekotest

/etc/cron.d/os-autoinst-scripts-update-git:
  file.managed:
    - contents:
      - '-*/3    * * * *  geekotest     git -C /opt/os-autoinst-scripts pull --quiet --rebase origin master'

{%- if not grains.get('noservices', False) %}
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

{% for type in ['service', 'timer'] %}
# Prevent server unresponsiveness due to TRIM which is also debatable anyway
# on virtual machines
# https://progress.opensuse.org/issues/164427
fstrim.{{ type }}:
  service.dead:
    - enable: False
{% endfor %}
{%- endif %}

/etc/cron.d/dump-openqa:
  file.managed:
    - mode: "0644"
    - contents: |
        40 23 * * * postgres backup_dir="/var/lib/openqa/backup"; date=$(date -Idate); bf="$backup_dir/$date.dump"; test -e "$bf" || ionice -c3 nice -n19 pg_dump -Fc openqa -f "$bf"; find $backup_dir/ -mtime +7 -print0 | xargs -0 rm -v
