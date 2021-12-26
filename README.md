# openQA salt states

This contains salt states used to configure an openQA infrastructure, for
example as used for openqa.suse.de .

They should be generic enough to also be useful (with some modification) for
others.

## How to use

### Initial setup of salt and repositories

```sh
. /etc/os-release
zypper ar -G http://download.suse.de/ibs/SUSE:/CA/${PRETTY_NAME// /_}/SUSE:CA.repo
zypper ref
zypper in ca-certificates-suse git-core salt-minion
echo "file_client: local" >> /etc/salt/minion
systemctl enable --now salt-minion

# checkout repositories
git -C /srv clone https://gitlab.suse.de/openqa/salt-states-openqa.git salt    # actual salt recipes
git -C /srv clone https://gitlab.suse.de/openqa/salt-pillars-openqa.git pillar # credentials such as SSH keys
```

To connect to the master, e.g. openqa.suse.de:

```
grep -q '\<salt\>' /etc/hosts || echo -e "10.160.0.207\tsalt\tsalt.openqa.suse.de" >> /etc/hosts
```

and accept the key on the master with `salt-key -y -a $host` with `$host`
being the name of the host as announced by the salt-minion.


### Common salt commands to use

Apply the complete configuration, so called "high state", to all nodes, while
only outputting errors and what changed:

```sh
salt -l error --state-output=changes \* state.apply highstate
```

Run an individual command on a selected node, for example openqaworker42:

```sh
salt 'openqaworker42*' cmd.run 'uptime'
```

Run a same command on all worker nodes, i.e. nodes with the role "worker", in
this example "systemctl --no-legend --failed" to show all failed systemd
services:

```sh
salt -C 'G@roles:worker' cmd.run 'systemctl --no-legend --failed'
```

Applies the specific state `stop_…_workers` from `worker.sls` on the specific
worker `openqaworker-arm-1.suse.de` with debug output enabled:

```sh
salt -l debug openqaworker-arm-1.suse.de state.sls_id stop_and_disable_all_not_configured_workers openqa.worker
```

Wipe and restart worker cache, restart all worker slots (e.g. useful when worker
services fail on all worker nodes due to problems with the cache service):

```sh
salt -C 'G@roles:worker' cmd.run 'systemctl stop openqa-worker-cacheservice openqa-worker-cacheservice-minion && rm -rf /var/lib/openqa/cache/* && systemctl start openqa-worker-cacheservice openqa-worker-cacheservice-minion && systemctl restart openqa-worker-auto-restart@*.service && until sudo systemctl status | grep -q "Jobs: 0 queue"; do sleep .1; done && systemctl --no-legend --failed'
```

To show the resulting target state and apply only that substate on nodes of a
specific role, e.g. the substate "monitoring.grafana" to all nodes
matching the role "monitor":

```sh
salt -C 'G@roles:monitor' state.show_sls,state.apply monitoring.influxdb,monitoring.influxdb
```

Add a worker host and apply the state immediately:

```sh
salt-key -y -a openqaworker13.suse.de
salt openqaworker13.suse.de state.apply
```

Remove a worker host:

```sh
salt-key -y -d openqaworker13.suse.de
```

## Testing
### Local test deployment

In a virtual or physical machine one can enable the use of the repository or
setup a test environment as explained above in the section
"Initial setup of salt and repositories".

As an alternative one can use a container and for example mount the local
working copy of states and/or pillars into the container:

```sh
podman run --rm -it -v $PWD:/srv/salt -v $PWD/../salt-pillars-openqa:/srv/pillar registry.opensuse.org/home/okurz/container/containers/tumbleweed:salt-minion-git-core
```

here assuming that the pillars repo can be found in a directory named
"salt-pillars-openqa" in a directory next to the states repo.

To test out all in a single call, e.g. that a file is generated correctly on a
monitoring instance:

```sh
podman run --rm -it -v $PWD:/srv/salt -v $PWD/../salt-pillars-openqa:/srv/pillar registry.opensuse.org/home/okurz/container/containers/tumbleweed:salt-minion-git-core sh -c 'echo -e "noservices: True\nroles: monitor" >> /etc/salt/grains && salt-call -l debug --local state.apply monitoring.grafana && cat /etc/grafana/ldap.toml'
```

Further common salt commands to execute in a local salt environment for
testing, debugging and investigation:

```sh
# apply all states
salt-call --local state.apply

# show verbose debug output
salt-call --local -l debug state.apply

# apply specific state (this example applies the state "firewalld" from file "workers.sls" within directory "openqa")
salt-call --local state.sls_id firewalld openqa.worker

# perform dry-run
salt-call --local state.sls_id firewalld openqa.worker test=True

# show all states in sls file (this example shows states from file "workers.sls" within directory "openqa")
salt-call --local state.show_sls openqa.worker

# show top-level structure defined in file "top.sls"
salt-call --local state.show_top
```

#### Grains
Grains (Python scripts found within `_grains` directory of this repository which are used to retrieve information
about the underlying system) can be executed and shown locally:

```
salt-call --local saltutil.sync_grains # use latest changes; should list changed Grains since last call
salt-call --local grains.items         # show Grain data
```

It is generally also possible to invoke grains directly via `python` but this way the execution environment might
not match the one from Salt and certain errors might not be reproducible.

Specific roles can be specified in salt grains, also for testing, e.g.:

```sh
echo 'roles: worker' > /etc/salt/grains
salt-call --local state.apply
```


### Test .gitlab-ci.yml locally

Run

```
make test
```

For the special deployment steps one can define the necessary variables
locally and override:

```
sudo gitlab-runner exec docker --env "SSH_PRIVATE_KEY=$SSH_PRIVATE_KEY" --env "TARGET=my.machine" --env "…" deploy
```


## Communication

If you have questions, visit us on IRC in [#opensuse-factory](irc://chat.freenode.net/opensuse-factory)


## Contribute

Feel free to add issues in the project or send pull requests.


### Rules for commits

* For git commit messages use the rules stated on
  [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/) as
  a reference

If this is too much hassle for you feel free to provide incomplete pull
requests for consideration or create an issue with a code change proposal.

## License

This project is licensed under the MIT license, see LICENSE file for details.
