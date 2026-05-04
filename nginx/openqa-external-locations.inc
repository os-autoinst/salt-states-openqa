{% if salt['pillar.get']('nginx:locations', []) %}
    {% for locations in pillar['nginx']['locations'] %}
        {% for location_name, item in locations.items() %}
            location ~ {{ item.location }} {
                return 301 {{ item.redirect }};
            }
        {% endfor %}
    {% endfor %}
{% endif %}
