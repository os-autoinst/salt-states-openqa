openQA:
  pkgrepo.managed:
    - humanname: openQA (SLE_12_SP1)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/SLE_12_SP1/
    - refresh: True
    - gpgcheck: False
    
openQA-perl-modules:
  pkgrepo.managed:
    - humanname: openQA-perl-modules (SLE_12_SP1)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA:/SLE-12/SLE_12_SP1/
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
