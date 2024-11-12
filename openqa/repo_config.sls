{% if 'Tumbleweed' in grains['oscodename'] %}
{% set repo = "openSUSE_Tumbleweed" %}
{% elif 'Leap' in grains['oscodename'] %}
{%   if grains['osmajorrelease'] == 15 and grains['osrelease_info'][1] < 4 %}
{%     set repo = "openSUSE_Leap_$releasever" %}
{%   else %}
{%     set repo = "$releasever" %}
{%   endif %}
{% elif 'SP3' in grains['oscodename'] %}
{% set repo = "SLE_12_SP3" %}
{% endif %}
{% set mirror = 'mirror.nue2.suse.org' if 'nue2.org' in grains.get('domain') else 'download.suse.de' %}
