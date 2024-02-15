{%- for package in pillar.get('locked_packages', []) %}
{{ package }}:
  pkg.held
{%- endfor %}
