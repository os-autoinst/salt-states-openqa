/etc/zypp/zypp.conf:
  ini.options_present:
    - sections:
        main:
          # We keep proper priorities on our repositories so we can rely on sensible,
          # automatic choices for vendor changes
          solver.dupAllowVendorChange: true

          # We have fast enough network - so no need to sactifice CPU
          download.use_deltarpm: false
