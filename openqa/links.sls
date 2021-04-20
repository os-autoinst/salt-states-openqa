{% from 'openqa/branding.sls' import branding %}
{% set branding_dir = '/usr/share/openqa/templates/webapi/branding/' + branding %}

{{ branding_dir }}/links_footer_left.html.ep:
    file.managed:
      - source: salt://openqa/links_footer_left.html
      - template: jinja
        links_footer:
          1:
            url: irc://irc.suse.de/testing
            description: IRC channel
          2:
            url: http://s.qa.suse.de/test-status
            description: Daily openQA review

{{ branding_dir }}/links_footer_right.html.ep:
    file.managed:
      - source: salt://openqa/links_footer_right.html
      - template: jinja
        links_footer:
          1:
            url: https://build.suse.de/staging_workflows/SUSE:SLE-15-SP3:GA
            description: SLE15 staging dashboard

{{ branding_dir }}/docbox.html.ep:
    file.managed:
      - source: salt://openqa/links_docbox.html
      - template: jinja
        links_docbox:
          1:
            url: http://open.qa
            description: » More information regarding openQA
          2:
            url: https://stats.openqa-monitor.qa.suse.de
            description: » Current openQA monitoring status
          3:
            url: https://wiki.suse.net/index.php/OpenQA
            description: » Description of internal setup and administration
