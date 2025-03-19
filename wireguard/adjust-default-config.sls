infra_managed_config_exists:
  file.exists:
    - name: /etc/wireguard/prg2wg.conf

# Our network segment provides a MTU of 1372 bytes. As we carry IPv6 traffic in it,
# we need to substract another 80 bytes from it resulting in a MTU of 1292 bytes.
# https://lists.zx2c4.com/pipermail/wireguard/2017-December/002201.html has more details.
/etc/wireguard/prg2wg.conf:
  ini.options_present:
    - sections:
        Interface:
          MTU: "1292"
    - require:
        - file: infra_managed_config_exists
