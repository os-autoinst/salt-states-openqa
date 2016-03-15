openQA:
  pkgrepo.managed:
    - humanname: openQA (Leap 42.1)
    - baseurl: http://download.opensuse.org/repositories/devel:/openQA/openSUSE_Leap_42.1/
    - gpgcheck: 0
    - autorefresh: 1
    
worker-openqa.packages: # Packages that must come from the openQA repo
  pkg.installed:
    - pkgs:
      - openQA-worker
      - xterm-console
      - freeimpi
    - fromrepo: openQA

worker.packages: # Packages that can come from anywhere
  pkg.installed:
    - pkgs:
      - xorg-x11-Xvnc
      - qemu-ovmf-x86_64
      - qemu: '>=2.3'
      
/var/lib/openqa/share:
  mount.mounted:
    - device: 'openqa.suse.de:/var/lib/openqa/share'
    - fstype: nfs4
    - opts: ro
    - require:
     - pkg: worker-openqa.packages
