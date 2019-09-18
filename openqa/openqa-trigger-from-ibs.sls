geekotest:
  user:
    - present

git:
  pkg.installed

python3:
  pkg.installed

/opt/openqa-trigger-from-ibs:
  file.directory:
    - name: /opt/openqa-trigger-from-ibs
    - user: geekotest

openqa-trigger-from-ibs:
  git.latest:
    - name: https://gitlab.suse.de/openqa/openqa-trigger-from-ibs
    - target: /opt/openqa-trigger-from-ibs
    - user: geekotest

{% for i in ['A','B','C','D','E','F','G','H','S','Y','V'] %}
SUSE:SLE-15-SP2:GA:Staging:{{ i }}:
  cmd.run:
    - name: su geekotest -c 'mkdir -p SUSE:SLE-15-SP2:GA:Staging:{{ i }} && python3 scriptgen.py SUSE:SLE-15-SP2:GA:Staging:{{ i }}'
    - cwd: /opt/openqa-trigger-from-ibs
{% endfor %}
