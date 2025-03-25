infra_managed_config_exists:
  file.exists:
    - name: /etc/wireguard/prg2wg.conf

# Our network segment provides a MTU of 1360 bytes (see network/nue2.sls).
# As we carry IPv6 traffic in our wg tunnel, we need to substract another 20 bytes
# from the automatically calculated 1280 resulting in a MTU of 1260 bytes for our tunnel.
# https://lists.zx2c4.com/pipermail/wireguard/2017-December/002201.html has more details.
/etc/wireguard/prg2wg.conf:
  ini.options_present:
    - sections:
        Interface:
          MTU: "1260"
    - require:
        - file: infra_managed_config_exists
