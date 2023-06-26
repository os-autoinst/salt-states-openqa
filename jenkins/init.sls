jenkins.repo:
  pkgrepo.managed:
    - humanname: Jenkins CI
    - baseurl: https://pkg.origin.jenkins.io/opensuse-stable/
    - gpgautoimport: True
    - refresh: True
    - priority: 105
    - require_in:
      - pkg: jenkins

  pkg.latest:
    - name: jenkins
    - refresh: False

/usr/local/bin/update-jenkins-plugins:
  file.managed:
    - source: salt://jenkins/update-jenkins-plugins
    - mode: "0755"

{%- if not grains.get('noservices', False) %}
{% for type in ['service', 'timer'] %}
jenkins_plugins_update_{{ type }}:
  file.managed:
    - name: /etc/systemd/system/jenkins-plugins-update.{{ type }}
    - source: salt://jenkins/jenkins-plugins-update.{{ type }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: jenkins_plugins_update_{{ type }}
{% endfor %}

jenkins-plugins-update.timer:
  service.running:
    - enable: True
    - require:
      - jenkins_plugins_update_timer
{%- endif %}
