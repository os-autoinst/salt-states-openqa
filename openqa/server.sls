include:
 - openqa.repos
 - openqa.journal
 - openqa.ntp
 - logrotate

server.packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - openQA
      - apache2
      - perl-Mojo-RabbitMQ-Client
      - perl-IPC-System-Simple
      - telegraf
      - vsftpd
      - samba
      - postfix
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
          download_domains: suse.de nue.suse.com
          recognized_referers: bugzilla.suse.com bugzilla.opensuse.org bugzilla.novell.com bugzilla.microfocus.com progress.opensuse.org github.com build.suse.de
          max_rss_limit: 250000
        amqp:
          url: amqps://openqa:b45z45bz645tzrhwer@rabbit.suse.de:5671/
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
        obs_rsync:
          home: /opt/openqa-trigger-from-ibs
          project_status_url: https://api.suse.de/public/build/%%PROJECT/_result
        job_settings_ui:
          keys_to_render_as_links: YAML_SCHEDULE,YAML_TEST_DATA,AUTOYAST
    - require:
      - pkg: server.packages

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

/etc/telegraf/telegraf.conf:
  file.managed:
    - name: /etc/telegraf/telegraf.conf
    - template: jinja
    - source:
      - salt://openqa/telegraf-webui.conf
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: server.packages

/usr/lib/systemd/system/telegraf.service:
  file.managed:
    - name: /usr/lib/systemd/system/telegraf.service
    - source:
      - salt://openqa/telegraf.service
    - user: root
    - group: root
    - mode: 600
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

telegraf:
  service.running:
    - watch:
      - file: /etc/telegraf/telegraf.conf

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
{%- endif %}

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
    - watch:
      - file: /etc/vsftpd.conf
{%- endif %}

{%- if not grains.get('noservices', False) %}
apache2:
  service.running:
    - watch:
      - file: /etc/apache2/vhosts.d/openqa.conf
      - file: /etc/apache2/ssl.key/{{grains['fqdn']}}.key
      - file: /etc/apache2/ssl.crt/{{grains['fqdn']}}.crt
{%- endif %}

{%- if not grains.get('noservices', False) %}
salt-master.service:
  service.running:
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
