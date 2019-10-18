# openQA salt states

This contains salt states used to configure an openQA infrastructure, for example as used for openqa.suse.de and openqa.opensuse.org

They should be generic enough to also be useful (with some modification) for others

## Local test deployment

```sh
. /etc/os-release
zypper ar -G http://download.suse.de/ibs/SUSE:/CA/${PRETTY_NAME// /_}/SUSE:CA.repo
zypper ref
zypper in ca-certificates-suse git-core salt-minion
echo "file_client: local" >> /etc/salt/minion
systemctl enable --now salt-minion

pushd /srv/salt
git clone https://gitlab.suse.de/openqa/salt-states-openqa.git .
popd

salt-call --local state.apply
```

Specific roles can be specified in salt grains, also for testing, e.g.:

```
echo 'roles: worker' > /etc/salt/grains
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
