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
      - perl-Mojo-RabbitMQ-Client
      - perl-IPC-System-Simple
      - vsftpd
      - samba
      - postfix
      - html-xml-utils  # for https://github.com/os-autoinst/scripts/blob/master/openqa-label-known-issues
      - ca-certificates-suse  # for https://gitlab.suse.de/openqa/scripts

/etc/fstab:
  file.managed:
    - source:
      - salt://fstab
    - user: root
    - group: root

/etc/openqa/openqa.ini:
  ini.options_present:
    - sections:
        global:
          plugins: AMQP ObsRsync
          branding: openqa.suse.de
          scm: git
          download_domains: suse.de nue.suse.com opensuse.org
          recognized_referers: bugzilla.suse.com bugzilla.opensuse.org bugzilla.novell.com bugzilla.microfocus.com progress.opensuse.org github.com build.suse.de
          max_rss_limit: 250000
        logging:
          file: /var/log/openqa
        amqp:
          url: {{ pillar['server']['amqp_url'] }}
          topic_prefix: suse
        scm git:
          update_remote: 'origin'
          update_branch: 'origin/master'
          do_push: 'yes'
        openid:
          httpsonly: 1
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
          CURRENT: 30
        misc_limits:
          untracked_assets_storage_duration: 7
          result_cleanup_max_free_percentage: 20
          asset_cleanup_max_free_percentage: 20
        obs_rsync:
          home: /opt/openqa-trigger-from-ibs
          project_status_url: https://api.suse.de/public/build/%%PROJECT/_result
        job_settings_ui:
          keys_to_render_as_links: YAML_SCHEDULE,YAML_TEST_DATA,AUTOYAST
        hooks:
          # Some groups excluded that have too many expected failing jobs or special review workflows
          job_done_hook_failed: env host=openqa.suse.de exclude_group_regex='.*(Development|Public Cloud|Released|Others|Kernel|Virtualization).*' grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-and-investigate-hook
          job_done_hook_incomplete: env host=openqa.suse.de grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-hook
          job_done_hook_timeout_exceeded: env host=openqa.suse.de grep_timeout=60 nice ionice -c idle /opt/os-autoinst-scripts/openqa-label-known-issues-hook
        influxdb:
          ignored_failed_minion_jobs: obs_rsync_run obs_rsync_update_builds_text
    - require:
      - pkg: server.packages

/etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf:
  file.managed:
    - name: /etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf
    - mode: 644
    - source:
      - salt://openqa/openqa-hook-timeout.conf
    - makedirs: true
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
openqa-webui:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - ini: /etc/openqa/openqa.ini

openqa-gru:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/systemd/system/openqa-gru.service.d/30-openqa-hook-timeout.conf
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
    - source:
      - salt://apache2/conf.d/server-status.conf
    - user: root
    - group: root
    - require:
      - pkg: server.packages

/etc/apache2/vhosts.d/openqa.conf:
  file.managed:
    - template: jinja
    - source:
      - salt://apache2/vhosts.d/openqa.conf
    - user: root
    - group: root
    - require:
      - pkg: server.packages

# ext_pillar is not available with master-less mode so using "noservices"
# check as workaround to disable the following in our test environment
{%- if not grains.get('noservices', False) %}
{% for i in ['key', 'crt'] %}
/etc/apache2/ssl.{{i}}/{{grains['fqdn']}}.{{i}}:
  file.managed:
    - contents_pillar: {{grains['fqdn']}}.{{i}}
{% endfor %}

# ssh key files and config for needle pushing
# https://progress.opensuse.org/issues/67804
# Generated with
# ``ssh-keygen -t ed25519 -N '' -C 'geekotest@openqa.suse.de, openqa-pusher needle pushing to gitlab' -f id_ed25519.gitlab`
/var/lib/openqa/.ssh/id_ed25519.gitlab:
  file.managed:
    - mode: 600
    - user: geekotest
    - group: nogroup
    - makedirs: True
    - contents_pillar: id_ed25519.gitlab

/var/lib/openqa/.ssh/id_ed25519.gitlab.pub:
  file.managed:
    - mode: 644
    - user: geekotest
    - group: nogroup
    - makedirs: True
    - contents_pillar: id_ed25519.gitlab.pub
{%- endif %}

/var/lib/openqa/.ssh/config:
  file.managed:
    - mode: 644
    - user: geekotest
    - group: nogroup
    - makedirs: True
    - contents: |
        Host gitlab.suse.de
          User gitlab
          IdentityFile ~/.ssh/id_ed25519.gitlab
          IdentitiesOnly yes

/etc/telegraf/telegraf.d/telegraf-webui.conf:
  file.managed:
    - template: jinja
    - source:
      - salt://monitoring/telegraf/telegraf-webui.conf
    - user: root
    - group: root
    - mode: 600
    - makedirs: True
    - require:
      - pkg: server.packages

{%- if not grains.get('noservices', False) %}
telegraf_sql_queries:
  postgres_user.present:
    - name: telegraf
    - login: True
  postgres_privileges.present:
    - name: telegraf
    - object_name: jobs
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

telegraf_db_job_groups:
  postgres_privileges.present:
    - name: telegraf
    - object_name: job_groups
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

telegraf_db_job_group_parents:
  postgres_privileges.present:
    - name: telegraf
    - object_name: job_group_parents
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

telegraf_db_workers:
  postgres_privileges.present:
    - name: telegraf
    - object_name: workers
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

readonly_db_access:
  postgres_user.present:
    - name: openqa
    - password: openqa

readonly_db_access_jobs:
  postgres_privileges.present:
    - name: openqa
    - object_name: jobs
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

readonly_db_access_job_modules:
  postgres_privileges.present:
    - name: openqa
    - object_name: job_modules
    - object_type: table
    - privileges:
      - SELECT
    - maintenance_db: openqa

# allow access to postgres database from outside so far this does not ensure
# that the configuration becomes effective which needs a server restart
/srv/PSQL10/data/postgresql.conf:
  file.replace:
    - pattern: "(listen_addresses = ')[^']*('.*$)"
    - repl: '\1*\2'

/srv/PSQL10/data/pg_hba.conf:
  file.append:
    - text: |
        host    all             openqa          0.0.0.0/0               md5
        host    all             openqa          ::/0                    md5
{%- endif %}

/etc/vsftpd.conf:
  file.managed:
    - source:
      - salt://vsftpd/vsftpd.conf
    - user: root
    - group: root
    - mode: 600
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
  service.running:
    - enable: True
    - watch:
      - file: /etc/apache2/vhosts.d/openqa.conf
      - file: /etc/apache2/ssl.key/{{grains['fqdn']}}.key
      - file: /etc/apache2/ssl.crt/{{grains['fqdn']}}.crt
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
    - source:
      - salt://postfix/sysconfig/mail
    - require:
      - pkg: server.packages

/etc/sysconfig/postfix:
  file.managed:
    - source:
      - salt://postfix/sysconfig/postfix

https://gitlab.suse.de/openqa/scripts.git:
  git.cloned:
    - target: /opt/openqa-scripts

openqa_scripts_config:
  # allow deployment to checked out branch from
  # https://gitlab.suse.de/openqa/scripts/blob/master/.gitlab-ci.yml
  git.config_set:
    - name: receive.denyCurrentBranch
    - value: ignore
    - repo: /opt/openqa-scripts

/opt/os-autoinst-scripts/:
  file.directory:
    - user: geekotest

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

/etc/systemd/journald.conf.d/journal_size.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [Journal]
        SystemMaxUse=80G
        SystemKeepFree=10%
