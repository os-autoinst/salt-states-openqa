/usr/share/openqa/templates/webapi/branding/openqa.suse.de/links_footer_left.html.ep:
  file.managed:
    - source: salt://openqa/links_footer_left.html
    - template: jinja
      links_footer:
        1:
          url: https://suse.slack.com/archives/C02CANHLANP
          description: Internal chat channel
        2:
          url: https://openqa.io.suse.de/openqa-review/
          description: Daily openQA review reports

/usr/share/openqa/templates/webapi/branding/openqa.suse.de/links_footer_right.html.ep:
  file.managed:
    - source: salt://openqa/links_footer_right.html
    - template: jinja
      links_footer:
        1:
          url: https://build.suse.de/staging_workflows/SUSE:SLE-15-SP5:GA
          description: SLE15 staging dashboard

/usr/share/openqa/templates/webapi/branding/openqa.suse.de/docbox.html.ep:
  file.managed:
    - source: salt://openqa/links_docbox.html
    - template: jinja
      links_docbox:
        1:
          url: http://open.qa
          description: » More information regarding openQA
        2:
          url: https://monitor.qa.suse.de
          description: » Current openQA monitoring status
        3:
          url: https://gitlab.suse.de/suse/wiki/-/blob/main/openqa.md
          description: » Description of internal setup and administration
