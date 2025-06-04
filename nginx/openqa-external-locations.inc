{% if pillar.get('locations', []) %}
    {% for locations in pillar['locations'] %}
        {% for location_name, item in locations.items() %}
            location ~ {{ item.location }} {
                return 301 {{ item.redirect }};
            }
        {% endfor %}
    {% endfor %}
{% endif %}
