gitlab_runner_vlan2242_config:
  file.managed:
    - mode: "0644"
    - user: root
    - group: root
    - makedirs: True
    - names:
      - /etc/gitlab_runner/config1/.runner_system_id:
        - mode: "0600"
        - contents_pillar: config1/.runner_system_id
      - /etc/gitlab_runner/config2/.runner_system_id:
        - mode: "0600"
        - contents_pillar: config2/.runner_system_id
      - /etc/gitlab_runner/config1/config.toml:
        - mode: "0600"
        - contents_pillar: config1/config.toml
      - /etc/gitlab_runner/config2/config.toml:
        - mode: "0600"
        - contents_pillar: config2/config.toml

server.packages:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5
    - resolve_capabilities: True
    - pkgs:
      - docker
      - docker-compose
      - python3-docker

{%- if not grains.get('noservices', False) %}
docker:
  service.running:
    - enable: True
{%- endif %}

gitlab_runner_image:
  docker_image.present:
    - name: gitlab/gitlab-runner:latest
    - require: docker

gitlab-runner1:
  docker_container.running:
    - name: gitlab-runner1
    - image: gitlab/gitlab-runner:latest
    - restart_policy: unless-stopped
    - binds:
        - /var/run/docker.sock:/var/run/docker.sock
        - /etc/gitlab_runner/config1:/etc/gitlab-runner
        - /var/lib/ca-certificates/ca-bundle.pem:/etc/gitlab-runner/certs/ca.crt:ro
    - require:
        - docker_image: gitlab_runner_image

gitlab-runner2:
  docker_container.running:
    - name: gitlab-runner2
    - image: gitlab/gitlab-runner:latest
    - restart_policy: unless-stopped
    - binds:
        - /var/run/docker.sock:/var/run/docker.sock
        - /etc/gitlab_runner/config2:/etc/gitlab-runner
        - /var/lib/ca-certificates/ca-bundle.pem:/etc/gitlab-runner/certs/ca.crt:ro
    - require:
        - docker_image: gitlab_runner_image


