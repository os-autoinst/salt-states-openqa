# openQA salt states

This contains salt states used to configure the openqa infrastructure for openqa.suse.de and openqa.opensuse.org

They should be generic enough to also be useful (with some modification) for others

## Local test deployment

```sh
zypper ar -G http://download.suse.de/ibs/SUSE:/CA/SLE_12_SP1/SUSE:CA.repo
zypper ar -G http://download.opensuse.org/repositories/systemsmanagement:/saltstack/SLE_12_SP1/systemsmanagement:saltstack.repo
zypper ref
zypper in ca-certificates-suse git-core salt-minion
echo "file_client: local" >> /etc/salt/minion
systemctl enable salt-minion
systemctl start salt-minion

pushd /srv/salt
git clone https://gitlab.suse.de/openqa/salt-states-openqa.git .
sed -i -e "s/openqa.suse.de/$(hostname -f)/" top.sls
popd

salt-call --local state.apply
```
