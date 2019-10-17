include:
 - openqa.repos
 - openqa.journal
 - openqa.ntp

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
        obs_rsync:
          home: /opt/openqa-trigger-from-ibs
          project_status_url: https://api.suse.de/public/build/%%PROJECT/_result?package=000product
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
telegraf:
  service.running:
    - watch:
      - file: /etc/telegraf/telegraf.conf
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
    - watch:
      - file: /etc/vsftpd.conf
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

{%- if not grains.get('noservices', False) %}
postfix:
  service.running:
    - watch:
      - file: /etc/sysconfig/mail
      - file: /etc/sysconfig/postfix
{%- endif %}
