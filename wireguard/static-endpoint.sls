{% set wg_endpoint = pillar.get('wg_endpoint', '.') %}
{% set ipv4 = salt["dnsutil.A"](wg_endpoint) %}
{% set ipv6 = salt["dnsutil.AAAA"](wg_endpoint) %}
{% set ip_list = [] %}

{%- if ipv4 is list %}
{% do ip_list.extend(ipv4) %}
{%- endif %}

{%- if ipv6 is list %}
{% do ip_list.extend(ipv6) %}
{%- endif %}

static_wg_hostname:
  host.present:
    - ip: {{ ip_list }}
    - names:
      - {{ wg_endpoint }}
