# Workaround for https://bugzilla.opensuse.org/show_bug.cgi?id=1181418
# Can be deleted if the corresponding bugreport is fixed.
# Please read the related commit message for more details.
/etc/logrotate.d/openvswitch:
  file.line:
    - after: "    su openvswitch openvswitch"
    - content: "    create openvswitch openvswitch"
    - mode: insert
