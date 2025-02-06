# openQA salt states

This contains salt states used to configure an openQA infrastructure, for
example as used for openqa.suse.de .

They should be generic enough to also be useful (with some modification) for
others.

## How to use
### Setup production machine
1. Before adding a host, ensure it has a proper DNS setup. That includes
   that the involved DNS server(s) need to have a valid reverse DNS entry so
   that each host is easily discoverable.
2. Ensure Salt and a few useful utilities are installed:
   `zypper in salt-minion git-core htop vim systemd-coredump`
3. Set `/etc/salt/minion_id` and `/etc/hostname` to the FQDN and hostname
   respectively.
4. Configure `/etc/salt/minion` similar to the other production hosts (by just
   appending what is configured on other production hosts)
    * Most importantly, set the "master", e.g. `echo 'master: openqa.suse.de' >> /etc/salt/minion`
5. Configure the machine's role by putting e.g. `/etc/salt/grains` in
   `roles: worker` if applicable. By default with a role only generic states
   will be
6. If it is an openQA worker, add it to `workerconf.sls` in our Salt pillars.
7. Invoke `systemctl enable --now salt-minion` and use to see what is happening
   `tail -f /var/log/salt/minion`.
8. Invoke `sudo salt-key --accept=…` on the "master" (e.g. OSD).
9. Run a command like `sudo salt -C 'G@nodename:… or G@nodename:…' -l error --state-output=changes state.apply`
   on the "master" until no failing salt states are remaining

### Clone repositories for using Salt locally
For using Salt repositories locally, check them out and use commands from the
"Local test deployment" section:
```
. /etc/os-release
zypper ar -G http://download.suse.de/ibs/SUSE:/CA/${PRETTY_NAME// /_}/SUSE:CA.repo
zypper in ca-certificates-suse git-core
git -C /srv clone https://gitlab.suse.de/openqa/salt-states-openqa.git salt    # actual salt recipes
git -C /srv clone https://gitlab.suse.de/openqa/salt-pillars-openqa.git pillar # credentials such as SSH keys
```

### Common salt commands to use

Apply the complete configuration, so called "high state", to all nodes, while
only outputting errors and what changed:

```sh
salt -l error --state-output=changes \* state.apply
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

Apply a specific state from any `.sls` file on any machine:
```sh
salt \* state.sls network.accept_ra
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

### Add salt manage package locks

Add a new file to [our pillars](https://gitlab.suse.de/openqa/salt-pillars-openqa/-/tree/master/packages/locks) expanding the existing `locked_packages`-list.
Multiple lists can coexist and will get merged by salt automatically if multiple apply to the same minion.
Assign this newly created list to all workers the lock should apply to. Advanced grain-matching can be used.
An example for such an entry can be found [here](https://gitlab.suse.de/openqa/salt-pillars-openqa/-/blob/6e7917eca9511074fb20816509405e148773cffb/top.sls#L16-17).

Our states will [ensure](https://gitlab.suse.de/openqa/salt-states-openqa/-/blob/master/openqa/auto-update.sh) this lock is in place and will take care of e.g. locking subsequent patches which would conflict with this salt managed lock.

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

Here assuming that the pillars repo can be found in a directory named
"salt-pillars-openqa" in a directory next to the states repo.

To test out all in a single call, e.g. that a file is generated correctly on a
monitoring instance:

```sh
podman run --rm -it -v $PWD:/srv/salt -v $PWD/../salt-pillars-openqa:/srv/pillar registry.opensuse.org/home/okurz/container/containers/tumbleweed:salt-minion-git-core sh -c 'echo -e "noservices: True\nroles: monitor" >> /etc/salt/grains && salt-call -l debug --local state.apply monitoring.grafana && cat /etc/grafana/ldap.toml'
```

To test out a single state, e.g. that `workers.ini` is generated correctly for a
specific worker instance, use a command like:

```sh
podman run --hostname=worker8 --rm -it -v $PWD:/srv/salt -v $PWD/../salt-pillars-openqa:/srv/pillar registry.opensuse.org/home/okurz/container/containers/tumbleweed:salt-minion-git-core sh -c 'echo -e "roles: worker\ncpu_flags:" "\n  - "{cx16,lahf_lm,popcnt,sse4_1,sse4_2,ssse3} >> /etc/salt/grains && salt-call -ldebug --local saltutil.sync_all && mkdir /etc/openqa && salt-call -l debug --local state.sls_id '/etc/openqa/workers.ini' openqa.worker && cat /etc/openqa/workers.ini'
```

Further remarks about the previous command:
* We mock `grains['host']` by specifying `--hostname …` when starting the container.
* We mock further particularities of the worker by writing additional grains to `/etc/salt/grains`
  which will override salt-provided values.
* We ensure custom grains are loaded by calling `saltutil.sync_grains` before the actual `state.…`
  command.
* To speed things up I have temporarily removed `pkg: worker.packages` from the state and create
  the directory `/etc/openqa` manually instead. Hacks like this can speed up testing tremendously.

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

### CI tests
Changes provided in merge requests are tested with GitLab CI tests. These tests
are using a set of test pillars found within this repository's subdirectory
`t/pillar`.

## Linting

Run `make check` to check YAML files (e.g. for duplicate keys).

> `make check` runs *yamllint* against sls files. If the sls includes some
> templating, it is recommended to exclude this file from the checks.
> This should occur automatically if Jinja templating delimiters are detected
> inside the sls file. Otherwise, you might do that manually by editing
> .yamllint configuration file.
>
> ```
> ignore: |
>   myfile.sls
> ```

You can also run `make tidy` to automatically format the YAML files.

## Take out worker slots from production temporarily
**The easiest** way to take out worker slots temporarily is to keep them running
and just remove any production worker classes from `/etc/openqa/workers.ini`.
You need to stop Salt via `systemctl stop salt-minion.service` so it will not
change the config back. Otherwise, you don't have to invoke any systemd commands
because the workers will apply the config change automatically.

If you really want to stop the worker slots, read the next section for how to do
it correctly.

## Remarks about the systemd-units used to start workers
The salt states achieve a setup which allows stopping/restarting workers without
interrupting currently running jobs following the corresponding [upstream
documentation](https://open.qa/docs/#_stoppingrestarting_workers_without_interrupting_currently_running_jobs).

So `openqa-worker-plain@.service` services and `openqa-worker.target` are
disabled/stopped in this setup. The units `openqa-worker-auto-restart@.service`,
`openqa-reload-worker-auto-restart@.service` and
`openqa-reload-worker-auto-restart@.path` are used instead. Keep that in mind
when manually starting/stopping/masking units. It makes most sense to
mask/unmask all three units types only in accordance.

Due to the fact that the generic `openqa-worker@.service` is pointed to the
`openqa-worker-auto-restart@.service`, it should be generally safe to to use
any of those two names for systemd commands. Please note, the service will
still list itself under its real name, i.e.
`openqa-worker-auto-restart@.service`.

To take out worker slots temporarily, checkout the section above. If you want to
keep Salt running and disable the slots completely, you can mask the services
instead. This will also prevent Salt from starting/enabling them again.

### Examples
Take out particular worker slots:
```
systemctl mask --now openqa-worker-auto-restart@{20,21}.service openqa-reload-worker-auto-restart@{20,21}.{service,path}
```

To avoid spelling out the service names manually one can use the helper script
`openqa-worker-services`. So the following example is equivalent to the previous
one:
```
systemctl mask --now $(openqa-worker-services --masking 20 21)
```

This helper script returns all worker slots if no arguments are provided. So one
can for instance restart all slots easily like this (without explicitly
specifying the number of slots):
```
systemctl restart $(openqa-worker-services)
```


Take out particular worker slots without interrupting ongoing jobs:
```
systemctl mask --now $(openqa-worker-services --masking --reload-only 20 21)
systemctl mask $(openqa-worker-services 20 21)
systemctl kill --kill-who=main --signal HUP $(openqa-worker-services 20 21)
```

Find currently masked units:
```
systemctl list-unit-files --state=masked
```

Bring back particular worker slots:
```
systemctl unmask $(openqa-worker-services --masking 20 21)
systemctl start $(openqa-worker-services --starting 20 21)
```

## Testing specific template rendering locally
First, make sure you have the correct role set in `/etc/salt/grains`, e.g. if
you want to render a worker-specific template this file needs to contain
`roles: worker`. You may also add additional values like `host: worker37` to
test specific branches within the template.

You will need values from pillars. It might be sufficient to specify the
directory `t/pillar` contained by this repository. However, you can also point
it to your production pillar repository as it is done in the subsequent
examples. The subsequent commands need to be executed at the root of a checkout
of this repository and expect a checkout of the production pillars next to it.

To test whether pillar data can be loaded correctly for the role you want to
test with, use the following command:

```
sudo salt-call --pillar-root=../salt-pillars-openqa --local pillar.ls
```

You can use a command like the following to render a template and see whether
it is valid YAML:

```
sudo salt-call --out=json --pillar-root=../salt-pillars-openqa --local slsutil.renderer "$PWD/openqa/worker.sls" default_renderer=jinja | jq -r .local | yq
```

The section "Test alert provisioning locally" below contains another example
which shows how to add additional variables to the command-line.

## Hints about using Grafana

### Updating alert rules with the help of the Grafana web UI
1. Copy the provisioned alert you want to update.
    1. Select the alert under "Alerts". If the same alert exists for multiple hosts
       it is templated which must be taken into account later. For now, just pick
       any of those alerts.
    2. Click on the "Copy" button in the "Actions" column and and proceed despite
       the warning.
2. In the editor opened by the copy action, do the changes you want to do. Do *not*
   save yet.
3. Additionally, do the following changes:
    * In section 1: Enter a title that makes it easy to find the alert later.
    * In section 3: Select a different folder, e.g. "WIP". This makes it clear
      that the alert is none of our normal production alerts.
    * In section 5: Remove the label "osd-admins". This avoids notification mails
      to the team.
4. Save the alert.
5. Create an API key under https://monitor.qa.suse.de/org/apikeys if
   you don't already have one. The role needs to be "Admin".
6. Determine the alert's ID via the title entered in step 3. and get its YAML
   representation:
   ```
   url=https://monitor.qa.suse.de/api/v1/provisioning/alert-rules
   key=… # the API key from step 5.
   uid=$(curl -H "Authorization: Bearer $key" "$url" | jq -r '.[] | select(.title == "Testrule") | .uid')
   yaml=$(curl -H "Authorization: Bearer $key" "$url/$uid/export")
   ```
   Note that the UID is also shown in the browser's URL-bar when viewing/editing
   the alert.
7. Update the relevant section in the relevant YAML file in this repository. There
   is one file per dashboard. The relevant file is the one matching the alert rule's
   "Dashboard UID".
    * `monitoring/grafana/alerting`: contains alerts not using templates
    * `monitoring/grafana/aleting-dashboard-*`: contains alerts using templates
        * Replace the concrete host/worker name with the placeholder (e.g. `{{ worker }}`)
          again.
8. After the merge request has been merged and deployed, restart Grafana and check
   whether everything is in-place.
9. Delete the temporarily created copy of the original alert again. This can be
   done via the web UI or API:
   ```
   curl -H "Authorization: Bearer $key" -X DELETE "$url/$uid"
   ```

### Remarks about alerting API
* The API routes mentioned in previous sections are documented in the
  [official documentation](https://grafana.com/docs/grafana/latest/developers/http_api/alerting_provisioning).
  Replace the "latest" in that URL with e.g. "v9.3" to view the documentation
  page for an earlier version. This can be useful if the latest version hasn't
  been deployed yet to see the subset of routes actually available. Note that
  the documentation of [api/alerting](https://grafana.com/docs/grafana/v8.4/http_api/alerting)
  is not relevant as it is only about legacy alerts.
* All Grafana API routes can be browsed using the
  [Swagger Editor](https://editor.swagger.io/?url=https%3A%2F%2Fraw.githubusercontent.com%2Fgrafana%2Fgrafana%2Fmain%2Fpkg%2Fservices%2Fngalert%2Fapi%2Ftooling%2Fpost.json).
  This also reveals routes like `/api/ruler/grafana/api/v1/rules/{Namespace}/{Groupname}`
  which can be useful as well to delete alerts by folder/name.

### Test alert provisioning locally
Simply move the YAML files you want to test on your local Grafana instance
into `/etc/grafana/provisioning/alerting` and checkout the
[official documentation](https://grafana.com/docs/grafana/latest/alerting/set-up/provision-alerting-resources/file-provisioning)
for details.

For templated alert rules, one can render and deploy a specific template locally
by running e.g.:

```
sudo bash -c "salt-call --out=json \\
    --pillar-root=../salt-pillars-openqa --local slsutil.renderer \\
    '$PWD/monitoring/grafana/alerting-dashboard-WD.yaml.template' \\
    default_renderer=jinja worker=openqaworker14 host_interface=eth0 \\
  | jq -r '.local' > /etc/grafana/provisioning/alerting/test-alert.yaml"
```

Checkout the section "Testing specific template rendering locally" above for
further details.

In any case you need to restart Grafana (e.g.
`sudo systemctl restart grafana-server.service`) for any changes to have effect.

### Removing stale provisioned alerts
These steps show how to remove a stale provisioned alert for the example
alert with the rule UID `saltmaster_service_alert`.

1. Check whether the alert is actually not provisioned anymore, e.g. run:
   ```
   grep -R 'saltmaster_service_alert' /etc/grafana/provisioning/alerting
   ```
2. Ensure that `grafana-server.service` has been restarted after the provisioning
   file was removed.
3. If it is really a stale alert, remove it manually from the database:
   ```
   RULE_UID=saltmaster_service_alert
   sudo -u grafana sqlite3 /var/lib/grafana/grafana.db "
     delete from alert_rule where uid = '${RULE_UID}';
     delete from alert_rule_version where rule_uid = '${RULE_UID}';
     delete from provenance_type where record_key = '${RULE_UID}';
     delete from annotation where text like '%${RULE_UID}%';
    "
   ```
4. Check whether the alert is gone for good:
   ```
   sudo -u grafana sqlite3 /var/lib/grafana/grafana.db '.dump' | grep 'saltmaster_service_alert'`
   ```

#### Further remarks
To delete a bunch of alerts in one go it can be useful to use a regex. For
instance, to delete all alerts for hosts with names like `d160`, `d161`, … one
could use:

```
sudo -u grafana sqlite3 /var/lib/grafana/grafana.db "
  select uid from alert_rule where uid regexp '.*_alert_d\d\d\d';"
```

```
sudo -u grafana sqlite3 /var/lib/grafana/grafana.db "
  delete from alert_rule where uid regexp '.*_alert_d\d\d\d';
  delete from alert_rule_version where rule_uid regexp '.*_alert_d\d\d\d';
  delete from provenance_type where record_key regexp '.*_alert_d\d\d\d';
  delete from annotation where text regexp '.*_d\d\d\d';
 "
```

The first `select` is for checking whether the regex matches only intended rows.

## Multi-machine test setup
All worker hosts are configured according to the
[networking documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Networking.asciidoc)
of openQA. Only hosts that have the worker class `tap` and share common
`location-*` worker classes are interconnected via GRE-tunnels, though.

That means you can run test jobs using tap-based networking to verify a
newly-setup worker by using a worker class like `tap_pooXXX`. You only need to
avoid scheduling test jobs across multiple workers (but also don't have to worry
about impacting the production GRE-network yet).

## Wireguard
The required package and SSH key for Eng-Infra to connect are configured
automatically on relevant hosts. Checkout `wireguard/init.sls` for details. The
first line in that file can be modified to change the definition of "relevant
hosts".

Not all Wireguard-related configuration is contained by this Salt repository.
Checkout the
[Wiki page](https://gitlab.suse.de/suse/wiki/-/blob/main/qe_infrastructure.md#wireguard)
about our internal infrastructure for details.

## Communication

If you have questions, visit us on Matrix in https://matrix.to/#/#openqa:opensuse.org


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
