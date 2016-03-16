{% for machine, scripts in pillar.get('scripts', {}).items() %}
  {% for script, content in scripts.items() %}
   
    /etc/openqa/scripts/{{ machine }}_{{ script }}.sh:
      file.managed:
       - mode: 755
       - makedirs: True
       - contents:  |
          #!/bin/sh
  
          {{ content }}

  {% endfor %}
{% endfor %}

