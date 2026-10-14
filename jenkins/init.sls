include:
  - openqa.repos

{% set latest_java = salt['cmd.run']("zypper --xmlout --no-refresh --non-interactive search --provides java-openjdk-headless | grep -oE 'name=\"java-[0-9]+-openjdk-headless\"' | cut -d'\"' -f2 | sort -V | tail -n 1", python_shell=True, ignore_retcode=True) | trim %}

{% if not latest_java %}
java_determination_failed:
  test.fail_without_changes:
    - name: "Failed to determine the latest java-openjdk-headless package via zypper."
    - failhard: True
{% endif %}

jenkins.repo:
  pkgrepo.managed:
    - humanname: Jenkins CI
    - baseurl: https://pkg.origin.jenkins.io/opensuse-stable/
    - gpgautoimport: True
    - refresh: True
    - priority: 105
    - retry:
        attempts: 5
    - require_in:
      - pkg: jenkins

  pkg.installed:
    - name: jenkins
    - refresh: False

jenkins_java_pkg:
  pkg.installed:
    - name: {{ latest_java | tojson }}
    - refresh: False

jenkins_workflow_packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - pkgs:
        - os-autoinst-scripts-deps

/opt/os-autoinst-scripts:
  git.latest:
    - name: https://github.com/os-autoinst/os-autoinst-scripts.git
    - target: /opt/os-autoinst-scripts
    - force_reset: True

/usr/local/bin/update-jenkins-plugins:
  file.managed:
    - source: salt://jenkins/update-jenkins-plugins
    - mode: "0755"

{%- if not grains.get('noservices', False) %}

jenkins.service:
  service.running:
    - enable: True
    - require:
      - pkg: jenkins.repo
      - pkg: jenkins_java_pkg
    - watch:
      - pkg: jenkins.repo
      - pkg: jenkins_java_pkg

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
