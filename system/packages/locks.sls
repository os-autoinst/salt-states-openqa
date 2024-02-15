{%- for package in pillar.get('locked_packages', []) %}
{{ package["name"] }}:
  pkg.held
{%- endfor %}
