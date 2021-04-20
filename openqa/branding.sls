{% if 'suse.de' in grains['fqdn'] %}
{% set branding = 'openqa.suse.de' %}
{% elif 'opensuse' in grains['fqdn'] %}
{% set branding = 'openSUSE' %}
{% else %}
{% set branding = 'plain' %}
{% endif %}
