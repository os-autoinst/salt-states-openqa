devel_openQA:
  pkgrepo.managed:
    - humanname: devel:openQA
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/openSUSE_Leap_$releasever/
    - refresh: True
    - gpgautoimport: True

devel_openQA_Leap:
  pkgrepo.managed:
    - humanname: devel:openQA:Leap
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/Leap:/$releasever/openSUSE_Leap_$releasever/
    - refresh: True
    - gpgautoimport: True

telegraf-monitoring:
  pkgrepo.managed:
    - humanname: devel:languages:go
    - baseurl: https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Leap_$releasever/
    - refresh: True
    - gpgautoimport: True

server.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - openQA
      - perl-Mojo-RabbitMQ-Client
      - perl-IPC-System-Simple
      - telegraf

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
          home: /usr/lib/openqa-trigger-from-ibs
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
