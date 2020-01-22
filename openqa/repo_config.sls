{% if 'Tumbleweed' in grains['oscodename'] %}
{% set repo = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{% set repo = "openSUSE_Leap_$releasever" %}
{% elif 'SP3' in grains['oscodename'] %}
{% set repo = "SLE_12_SP3" %}
{% endif %}
