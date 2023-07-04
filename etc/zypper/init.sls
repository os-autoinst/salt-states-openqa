# We keep proper priorities on our repositories so we can rely on sensible,
# automatic choices for vendor changes
/etc/zypp/zypp.conf:
  ini.options_present:
    - sections:
        main:
          solver.dupAllowVendorChange: true
