geekotest:
  user:
    - present

git:
  pkg.installed

python3:
  pkg.installed

/usr/lib/openqa-trigger-from-ibs:
  file.directory:
    - name: /usr/lib/openqa-trigger-from-ibs
    - user: geekotest

openqa-trigger-from-ibs:
  git.latest:
    - name: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs
    - target: /usr/lib/openqa-trigger-from-ibs
    - user: geekotest

SUSE:SLE-15-SP2:GA:Staging:B:
  cmd.run:
    - name: su geekotest -c 'mkdir -p SUSE:SLE-15-SP2:GA:Staging:B && python3 scriptgen.py SUSE:SLE-15-SP2:GA:Staging:B'
    - cwd: /usr/lib/openqa-trigger-from-ibs

SUSE:SLE-15-SP2:GA:Staging:Y:
  cmd.run:
    - name: su geekotest -c 'mkdir -p SUSE:SLE-15-SP2:GA:Staging:Y && python3 scriptgen.py SUSE:SLE-15-SP2:GA:Staging:Y'
    - cwd: /usr/lib/openqa-trigger-from-ibs
