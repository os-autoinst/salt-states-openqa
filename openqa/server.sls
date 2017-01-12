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
        amqp:
          # tmp server for first steps into AMQP world; maintained by dheidler
          url: amqp://guest:guest@kazhua.suse.de:5672/
          topic_prefix: suse
    - require:
      - pkg: server.packages
