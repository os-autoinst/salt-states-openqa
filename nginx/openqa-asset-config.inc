{%- set limit_rate = salt['pillar.get']('nginx:asset_limit_rate', '0') -%}
{%- if limit_rate != '0' %}
limit_rate {{ limit_rate }};
{%- endif %}
autoindex          on;
tcp_nopush         on;
sendfile           on;
sendfile_max_chunk 1m;
