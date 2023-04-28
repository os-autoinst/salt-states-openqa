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
systemctl enable --now salt-minion
```

To connect to the master, e.g. openqa.suse.de:

```
grep -q '\<openqa.suse.de\>' /etc/salt/minion || echo "master: openqa.suse.de" >> /etc/salt/minion
```

and accept the key on the master with `salt-key -y -a $host` with `$host`
being the name of the host as announced by the salt-minion.

For using Salt repositories locally, check them out and use commands from the
"Local test deployment" section:
```
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

### CI tests
Changes provided in merge requests are tested with GitLab CI tests. These tests
are using a set of test pillars found within this repository's subdirectory
`t/pillar`.

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

Note that for taking out particular worker slots, masking services is generally
needed (and disabling/stopping the services not sufficient) because otherwise
salt will automatically enable/start the services again.

### Examples
Take out particular worker slots:
```
systemctl mask --now openqa-worker-auto-restart@{20,21}.service openqa-reload-worker-auto-restart@{20,21}.{service,path}
```

Take out particular worker slots without interrupting ongoing jobs:
```
systemctl mask --now openqa-reload-worker-auto-restart@{20,21}.{service,path}
systemctl mask openqa-worker-auto-restart@{20,21}.service
systemctl kill --kill-who=main --signal HUP openqa-worker-auto-restart@{20,21}.service
```

Find currently masked units:
```
systemctl list-unit-files --state=masked
```

Bring back particular worker slots:
```
systemctl unmask openqa-worker-auto-restart@{20,21}.service openqa-reload-worker-auto-restart@{20,21}.{service,path}
systemctl start openqa-worker-auto-restart@{20,21}.service openqa-reload-worker-auto-restart@{20,21}.path
```

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
5. Create an API key under https://stats.openqa-monitor.qa.suse.de/org/apikeys if
   you don't already have one. The role needs to be "Admin".
6. Determine the alert's ID via the title entered in step 3. and get its YAML
   representation:
   ```
   url=https://stats.openqa-monitor.qa.suse.de/api/v1/provisioning/alert-rules
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
    default_renderer=jinja worker=openqaworker14 \\
  | jq -r '.local' > /etc/grafana/provisioning/alerting/test-alert.yaml"
```

This example assumes pillars are checked out locally as well, next to the states
repository. You could of course also specify a different path, e.g. `t/pillar` for
pillars included in the states repository for test purposes.

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
   sudo -u grafana sqlite3 /var/lib/grafana/grafana.db "
     delete from alert_rule where uid = 'saltmaster_service_alert';
     delete from alert_rule_version where rule_uid = 'saltmaster_service_alert';
     delete from provenance_type where record_key = 'saltmaster_service_alert';
     delete from annotation where text like '%saltmaster_service_alert%';
    "
   ```
4. Check whether the alert is gone for good:
   ```
   sudo -u grafana sqlite3 /var/lib/grafana/grafana.db '.dump' | grep 'saltmaster_service_alert'`
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
