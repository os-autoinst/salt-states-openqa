openQA:
  pkgrepo.managed:
    - humanname: openQA (Leap 42.2)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/openSUSE_Leap_42.2/
    - refresh: True
    - gpgcheck: False

openQA-perl-modules:
  pkgrepo.managed:
    - humanname: openQA-perl-modules (Leap 42.2)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/Leap:/42.2/openSUSE_Leap_42.2/
    - refresh: True
    - gpgcheck: False

server.packages:
  pkg.installed:
    - refresh: True
    - pkgs:
      - openQA
      - perl-Mojo-RabbitMQ-Client

/etc/openqa/openqa.ini:
  ini.options_present:
    - sections:
        global:
          plugins: AMQP
          branding: openqa.suse.de
          scm: git
          download_domains: suse.de nue.suse.com
          recognized_referers: bugzilla.suse.com bugzilla.opensuse.org bugzilla.novell.com bugzilla.microfocus.com progress.opensuse.org github.com build.suse.de
          max_rss_limit: 400000
        amqp:
          url: amqps://openqa:b45z45bz645tzrhwer@rabbit.suse.de:5671/
          topic_prefix: suse
        scm git:
          do_push: yes
        openid:
          httpsonly: 1
        logging:
          file: /var/log/openqa
    - require:
      - pkg: server.packages
