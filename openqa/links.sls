/usr/share/openqa/templates/branding/openqa.suse.de/links_footer_left.html.ep:
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

/usr/share/openqa/templates/branding/openqa.suse.de/links_footer_right.html.ep:
    file.managed:
      - source: salt://openqa/links_footer_right.html
      - template: jinja
        links_footer:
          1:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP5:GA
            description: SLE12 staging dashboard
          2:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-15-SP2:GA
            description: SLE15 staging dashboard
          3:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP3:Update:Products:CASP30
            description: CaaSP staging dashboard

/usr/share/openqa/templates/branding/openqa.suse.de/docbox.html.ep:
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
