/boot/efi/extraconfig.txt:
  file.managed:
    - create: true
    - contents: |
        dtparam=i2c_arm=on
        device_tree=bcm2711-rpi-4-b.dtb
        dtoverlay=i2c-rtc,ds1307
