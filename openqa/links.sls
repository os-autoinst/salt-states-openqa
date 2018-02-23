/usr/share/openqa/templates/branding/openqa.suse.de/links_footer_left.html.ep:
    file.managed:
      - source: salt://openqa/links_footer_left.html
      - template: jinja
        links_footer:
          1:
            url: irc://irc.suse.de/testing
            description: IRC channel
          2:
            url: https://w3.suse.de/~okurz/openqa_suse_de_status.html
            description: Daily openQA review

/usr/share/openqa/templates/branding/openqa.suse.de/links_footer_right.html.ep:
    file.managed:
      - source: salt://openqa/links_footer_right.html
      - template: jinja
        links_footer:
          1:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP3:GA
            description: SLE staging dashboard
          2:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP2:Update:Products:CASP10
            description: CaaSP staging dashboard

/usr/share/openqa/templates/branding/openqa.suse.de/docbox.html.ep:
    file.managed:
      - source: salt://openqa/links_docbox.html
      - template: jinja
        links_docbox:
          1:
            url: http://os-autoinst.github.io/openQA/
            description: » More information regarding openQA
          2:
            url: https://wiki.microfocus.net/index.php/OpenQA
            description: » Description of internal setup and administration
