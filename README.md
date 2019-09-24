# openQA salt states

This contains salt states used to configure the openqa infrastructure for openqa.suse.de and openqa.opensuse.org

They should be generic enough to also be useful (with some modification) for others

## Local test deployment

```sh
. /etc/os-release
zypper ar -G http://download.suse.de/ibs/SUSE:/CA/${PRETTY_NAME// /_}/SUSE:CA.repo
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

## Test .gitlab-ci.yml locally

Run

```
make test
```

For the special deployment steps one can define the necessary variables
locally and override:

```
sudo gitlab-runner exec docker --env "SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY" --env "TARGET=my.machine" --env "…" deploy
```
