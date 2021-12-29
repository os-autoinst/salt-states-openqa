.PHONY: all
all: test

.PHONY: prepare
prepare:
	command -v gitlab-ci-linter >/dev/null || (sudo wget -q https://dl.bintray.com/orobardet/gitlab-ci-linter/v2.2.0/gitlab-ci-linter.linux-amd64 -O /usr/local/bin/gitlab-ci-linter && \
		sudo chmod +x /usr/local/bin/gitlab-ci-linter)

.PHONY: test
test: prepare
	yamllint .gitlab-ci.yml
	gitlab-ci-linter --gitlab-url https://gitlab.nue.suse.com
	/usr/sbin/gitlab-runner exec docker 'test-general'
	/usr/sbin/gitlab-runner exec docker 'test-webui'
	/usr/sbin/gitlab-runner exec docker 'test-worker'
	/usr/sbin/gitlab-runner exec docker 'test-monitor'
	/usr/sbin/gitlab-runner exec docker 'test-storage'
