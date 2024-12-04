wireguard.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - wireguard-tools

# deploy SSH key to allow Eng-Infra configuring the machine
{%- set wg_pub_ssh_key =  pillar.get('commonconf', {}).get('wg_pub_ssh_key', '') %}
{%- if wg_pub_ssh_key %}
/root/.ssh/authorized_keys:
  file.append:
    - text: '{{ wg_pub_ssh_key }}'
{%- endif %}
