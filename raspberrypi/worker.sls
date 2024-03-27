worker.packages:
  pkg.installed:
    - refresh: False
    - retry:  # some packages can change rapidly in our repos needing a retry as zypper does not do that
        attempts: 5
    - pkgs:
      - openQA-worker
      - xterm-console
      - os-autoinst-distri-opensuse-deps
      - qemu-tools # for qemu-img needed for sd flashing
      - icewm-lite # for localXvnc console
      - xorg-x11-Xvnc # for localXvnc console
      - xdotool # for ssh-x

/etc/openqa/workers.ini:
  file.managed:
    - create: True
    - contents: |
        [global]
        HOST = openqa.suse.de
        GENERAL_HW_CMD_DIR = /var/lib/openqa/share/tests/opensuse/data/generalhw_scripts
        WORKER_HOSTNAME = 10.168.192.111
        RPI_WIFI_PSK = {{ pillar['pi']['wifi_psk'] }}
        RPI_WIFI_WORKER_IP = 192.168.7.1

        [1]
        # Raspberry Pi 4 B - dc:a6:32:5f:0e:a8
        # Most config moved to openQA `MACHINE` defintion due to https://progress.opensuse.org/issues/63766

        GENERAL_HW_FLASH_ARGS = 000000001006
        GENERAL_HW_FLASH_CMD = flash_sd_rootless.sh

        GENERAL_HW_POWEROFF_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWEROFF_ARGS = 192.168.7.11 off
        GENERAL_HW_POWERON_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWERON_ARGS = 192.168.7.11 on

        GENERAL_HW_SOL_CMD = get_sol_dev.sh
        GENERAL_HW_SOL_ARGS = serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.4:1.0-port0

        #GENERAL_HW_VIDEO_STREAM_URL = /dev/v4l/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.2:1.0-video-index0
        #GENERAL_HW_KEYBOARD_URL = http://192.168.7.21/cmd

        GENERAL_HW_ALSA_CTRL_DEV=/dev/snd/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.3.2:1.0

        SUT_IP = 10.168.192.112
        WORKER_CLASS = generalhw_RPi4,generalhw_RPi4_TPM,generalhw_RPi4_RTC

        [2]
        # Raspberry Pi 3 B+ - b8:27:eb:63:25:6c
        # Most config moved to openQA `MACHINE` defintion due to https://progress.opensuse.org/issues/63766

        GENERAL_HW_FLASH_ARGS = 000000001512
        GENERAL_HW_FLASH_CMD = flash_sd_rootless.sh

        GENERAL_HW_POWEROFF_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWEROFF_ARGS = 192.168.7.12 off
        GENERAL_HW_POWERON_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWERON_ARGS = 192.168.7.12 on

        GENERAL_HW_SOL_CMD = get_sol_dev.sh
        GENERAL_HW_SOL_ARGS = serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.1.2:1.0-port0

        #GENERAL_HW_VIDEO_STREAM_URL = /dev/v4l/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.1:1.0-video-index0
        #GENERAL_HW_KEYBOARD_URL = http://192.168.7.22/cmd

        GENERAL_HW_ALSA_CTRL_DEV=/dev/snd/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.3.1:1.0

        SUT_IP = 10.168.192.113
        WORKER_CLASS = generalhw_RPi3B+

        [3]
        # Raspberry Pi 3 B v1.2 - b8:27:eb:f9:9b:a0
        # Most config moved to openQA `MACHINE` defintion due to https://progress.opensuse.org/issues/63766

        GENERAL_HW_FLASH_ARGS = 000000001085
        GENERAL_HW_FLASH_CMD = flash_sd_rootless.sh

        GENERAL_HW_POWEROFF_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWEROFF_ARGS = 192.168.7.13 off
        GENERAL_HW_POWERON_CMD = power_on_off_shelly.sh
        GENERAL_HW_POWERON_ARGS = 192.168.7.13 on

        GENERAL_HW_SOL_CMD = get_sol_dev.sh
        GENERAL_HW_SOL_ARGS = serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.1.1:1.0-port0

        #GENERAL_HW_VIDEO_STREAM_URL = /dev/v4l/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.4:1.0-video-index0
        #GENERAL_HW_KEYBOARD_URL = http://192.168.7.23/cmd

        GENERAL_HW_ALSA_CTRL_DEV=/dev/snd/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.3.4:1.0

        SUT_IP = 10.168.192.114
        WORKER_CLASS = generalhw_RPi3B

/etc/systemd/system/openqa-worker-plain@.service.d/override.conf:
  file.managed:
    - create: True
    - contents: |
        [Service]
        Restart=always
        RestartSec=10s

# make the SD card survive
/var/lib/openqa/pool:
  mount.mounted:
    - device: tmpfs
    - fstype: tmpfs
    - mount: True

openqa-worker@1:
  service.running:
    - enable: True
    - watch:
      - file: /etc/openqa/workers.ini

openqa-worker@2:
  service.running:
    - enable: True
    - watch:
      - file: /etc/openqa/workers.ini

openqa-worker@3:
  service.running:
    - enable: True
    - watch:
      - file: /etc/openqa/workers.ini
