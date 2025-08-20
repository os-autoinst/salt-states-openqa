nfsclient.pkgs:
  pkg.installed:
    - refresh: false
    - retry:
        attempts: 5
    - pkgs:
        - nfs-client

nfs_backup_prg2_mounted:
  mount.fstab_present:
    # NFS share on prg2 netapp
    - name: "nfs-prg2-fas-prod.openplatform.suse.com:/openqa-backup-storage"
    - fs_file: /storage
    - fs_vfstype: nfs
    - fs_mntops: "rw,nofail,retry=30,x-systemd.mount-timeout=30m,x-systemd.automount,nolock"
    - not_change: false
