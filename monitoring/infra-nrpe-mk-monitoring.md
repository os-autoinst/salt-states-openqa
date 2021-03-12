## Description

This file describes the steps required (so far) to configure monitoring for openQA workers using the [thruk] (https://thruk.suse.de) and [nagios] (https://nagios-devel.suse.de/pnp4nagios/graph?host=openqa.suse.de) instances maintained by Infra.

Step-by-step documentation is described in [this document] (https://wiki.microfocus.net/index.php?title=SUSE-Development/OPS/Services/Monitoring) from the Infra team.

## Preparation

The following steps should be followed on each worker that is being included in the Infra monitoring:

1) Repositories:

```
sudo zypper ar -f http://download.suse.de/ibs/NON_Public:/infrastructure/openSUSE_Leap_$releasever/ NPI
sudo zypper ref
sudo zypper in -y check_mk-agent nrpe
```

2) check_mk configuration:

Edit `/etc/xinetd.d/check_mk` to add the addresses **10.100.2.20 10.160.0.40 10.160.0.44 10.160.0.45** to the line that has the command **only_from**.

3) Start & enable xinetd:

```
sudo systemctl start xinetd
sudo systemctl enable xinetd
```

4) Install monitoring plugins:

```
sudo zypper in -y monitoring-plugins-zypper monitoring-plugins-users monitoring-plugins-swap monitoring-plugins-sar-perf monitoring-plugins-procs monitoring-plugins-ntp_time monitoring-plugins-multipath monitoring-plugins-mem monitoring-plugins-load monitoring-plugins-ipmi-sensor1 monitoring-plugins-disk monitoring-plugins-common monitoring-plugins-bonding
```

5) nrpe configuration:

Edit `/etc/nrpe.cfg` and:

* Add monitoring servers IP address to line with **allowed_hosts**: allowed_hosts=127.0.0.1,10.100.2.20,10.160.0.40,10.160.0.44,10.160.0.45
* Comment line: command_timeout=60
* Comment lines starting with **command[**.
* Create directory **/etc/nagios**

6) Copy nagios zypper whitelist from openqa.suse.de and put it in /etc/nagios/check_zypper-ignores.txt

7) Place nrpe cfg files in `/etc/nrpe.d`, with the following names and content:

File: check_iostat.cfg
```
command[check_iostat_openqa]=/usr/lib/nagios/plugins/check_iostat -d nvme0n1p1 -w 10000,180000,180000 -c 15000,200000,200000 -W 50 -C 70
command[check_iostat_srv]=/usr/lib/nagios/plugins/check_iostat -d md1 -w 10000,120000,120000 -c 15000,150000,150000 -W 50 -C 70
```

File: check_memory.cfg
```
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 10 -c 5
command[check_mem]=/usr/lib/nagios/plugins/check_mem.pl -f -C -w 4 -c 2
```

File: check_misc.cfg
```
command[check_users]=/usr/lib/nagios/plugins/check_users -w 10 -c 20
command[check_load]=/usr/lib/nagios/plugins/check_load -w 80,80,80 -c 100,100,100
command[check_bonding]=/usr/lib/nagios/plugins/./check_bonding
command[check_multipath]=/usr/lib/nagios/plugins/check_multipath
```

File: check_ntp.cfg
```
command[check_ntp]=/usr/lib/nagios/plugins/check_ntp_time -H ntp1
```

File: check_partition_space.cfg
```
command[check_partition_root]=/usr/lib/nagios/plugins/./check_disk -u GB -w 8% -c 4% -p /
command[check_partition_space]=/usr/lib/nagios/plugins/./check_disk -u TB -w 85% -c 90% -p /var/lib/openqa
```

File: check_physical.cfg
```
command[check_temperature]=/usr/lib/nagios/plugins/check_ipmi_sensor1 -H localhost -T Temperature
command[check_voltage]=/usr/lib/nagios/plugins/check_ipmi_sensor1 -H localhost -T Voltage
command[check_fan]=/usr/lib/nagios/plugins/check_ipmi_sensor1 -H localhost -T Fan
```

File: check_proc_openqa.cfg
```
command[check_proc_openqa_openvswitch]=/usr/lib/nagios/plugins/./check_procs --argument-array=os-autoinst-openvswitch -u root -c 1:1024
command[check_proc_openqa_worker]=/usr/lib/nagios/plugins/./check_procs --argument-array=worker -u _openqa-worker -c 1:1024
```

File: check_procs.cfg
```
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 500 -c 750
command[check_proc_openqa_salt_minion]=/usr/lib/nagios/plugins/./check_procs --argument-array=salt-minion -u root -c 1:1024
command[check_proc_sshd]=/usr/lib/nagios/plugins/./check_procs --argument-array=sshd -u root -c 1:1024
```

File: check_zypper.cfg
```
command[check_zypper]=/usr/lib/nagios/plugins/check_zypper -vrst 120 -ui /etc/nagios/check_zypper-ignores.txt
```

8) Start and enable nrpe:

```
sudo systemctl start nrpe
sudo systemctl enable nrpe
```

9) Modify firewall to allow nrpe and Check_MK services connections.

**Note**: this is already covered for all workers via salt.

10) Create ticket for Infra team to finish configuration and include the server in the monitoring tool.

**Note**: Infra apparently needs to perform additional steps on the workers; at the time of the writing of this document it is not known what those steps are
