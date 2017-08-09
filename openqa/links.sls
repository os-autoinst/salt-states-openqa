/templates/branding/openqa.suse.de/links_footer.html.ep:
    file.managed:
      - source: salt://openqa/links_footer.html
      - template: jinja
        links_footer:
          1:
            url: irc://irc.suse.de/testing
            description: IRC channel
            position: left
          2:
            url: https://w3.suse.de/~okurz/openqa_suse_de_status.html
            description: Daily openQA review
            position: left
          3:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP3:GA
            description: SLE staging dashboard
            position: right
          4:
            url: https://build.suse.de/project/staging_projects/SUSE:SLE-12-SP2:Update:Products:CASP10
            description: CaaSP staging dashboard
            position: right

/templates/branding/openqa.suse.de/docbox.html.ep:
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
