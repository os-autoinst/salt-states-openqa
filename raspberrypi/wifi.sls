firewalld:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/sysconfig/network/ifcfg-br0:
  file.managed:
    - create: True
    - contents: |
        IPADDR='192.168.7.1/24'
        BOOTPROTO='static'
        STARTMODE='auto'
        BRIDGE='yes'
        BRIDGE_PORTS=''
        BRIDGE_STP='off'
        BRIDGE_FORWARDDELAY='15'
        ZONE=dmz

wicked ifup br0:
  cmd.run:
    - onchanges:
      - file: /etc/sysconfig/network/ifcfg-br0


/etc/firewalld/zones/dmz.xml:
  file.managed:
    - create: True
    - contents: |
        <?xml version="1.0" encoding="utf-8"?>
        <zone>
          <short>DMZ</short>
          <description>For computers in your demilitarized zone that are publicly-accessible with limited access to your internal network. Only selected incoming connections are accepted.</description>
          <interface name="br0"/>
        </zone>

/etc/firewalld/zones/public.xml:
  file.managed:
    - create: True
    - contents: |
        <?xml version="1.0" encoding="utf-8"?>
        <zone target="ACCEPT">
          <short>Public</short>
          <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
          <service name="ssh"/>
          <service name="dhcpv6-client"/>
          <interface name="eth0"/>
        </zone>

firewalld.service:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/firewalld/zones/*


dhcp-server:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/dhcpd.conf:
  file.managed:
    - create: True
    - contents: |
        subnet 192.168.7.0 netmask 255.255.255.0 {
            range 192.168.7.30 192.168.7.254;
        }
        host shelly1 { hardware ethernet e8:68:e7:c5:00:14; fixed-address 192.168.7.11; }
        host shelly2 { hardware ethernet 3c:61:05:f0:56:42; fixed-address 192.168.7.12; }
        host shelly3 { hardware ethernet 34:ab:95:1c:94:f0; fixed-address 192.168.7.13; }
        host pico1 { hardware ethernet 28:cd:c1:04:9b:4d; fixed-address 192.168.7.21; }
        host pico2 { hardware ethernet 28:cd:c1:09:d8:1e; fixed-address 192.168.7.22; }
        host pico3 { hardware ethernet 28:cd:c1:09:d8:1f; fixed-address 192.168.7.23; }

/etc/sysconfig/dhcpd:
  file.replace:
    - pattern: '^DHCPD_INTERFACE="[^"]*"'
    - repl: 'DHCPD_INTERFACE="br0"'

dhcpd.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/dhcpd.conf


hostapd:
  pkg.installed:
    - refresh: False
    - retry:
        attempts: 5

/etc/systemd/system/hostapd.service.d/override.conf:
  file.managed:
    - create: True
    - contents: |
        [Unit]
        BindsTo=sys-subsystem-net-devices-wlan0.device
        After=sys-subsystem-net-devices-wlan0.device

/etc/hostapd.conf:
  file.managed:
    - mode: "0600"
    - user: root
    - group: root
    - contents: |
        interface=wlan0
        bridge=br0
        ssid=openQA-worker
        wpa_passphrase={{ pillar['pi']['wifi_psk'] }}
        driver=nl80211
        country_code=DE
        hw_mode=g
        channel=7
        # Bit field: bit0 = WPA, bit1 = WPA2, 3=both
        wpa=2
        # Bit field: 1=wpa, 2=wep, 3=both
        auth_algs=1
        wpa_pairwise=CCMP
        wpa_key_mgmt=WPA-PSK
        logger_stdout=-1
        logger_stdout_level=2

hostapd.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/hostapd.conf
