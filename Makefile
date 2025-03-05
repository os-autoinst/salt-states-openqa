.PHONY: all
all: check test

.PHONY: prepare
prepare:
	command -v gitlab-ci-linter >/dev/null || (sudo wget -q https://gitlab.com/orobardet/gitlab-ci-linter/uploads/c4b64fb3b94473483dd2d02f0f32e1f6/gitlab-ci-linter.linux-amd64 -O /usr/local/bin/gitlab-ci-linter && \
		sudo chmod +x /usr/local/bin/gitlab-ci-linter)

.PHONY: test
test: prepare
	yamllint .gitlab-ci.yml
	gitlab-ci-linter --gitlab-url https://gitlab.suse.de
	/usr/sbin/gitlab-runner exec docker 'test-general'
	/usr/sbin/gitlab-runner exec docker 'test-webui'
	/usr/sbin/gitlab-runner exec docker 'test-worker'
	/usr/sbin/gitlab-runner exec docker 'test-monitor'
	/usr/sbin/gitlab-runner exec docker 'test-storage'

.PHONY: tidy
tidy:
	if command -v git >/dev/null; then \
			git ls-files -z "*.yml" "*.yaml"; else \
			find -name "*.yml" -or -name "*.yaml" -print0; fi | \
			xargs -n1 -0 yamltidy -i

.PHONY: check
check:
	# Check plain yaml files
	if command -v git >/dev/null; then \
			git ls-files -z "*.yml" "*.yaml"; else \
			find -name "*.yml" -or -name "*.yaml" -print0; fi | \
			xargs -0 yamllint -s
	# Check sls files without Jinja delimiters
	if command -v git >/dev/null; then \
			git ls-files -z "*.sls" | xargs -0r -- grep -LZF -e '{{' -e '{%' -e '{#'; else \
			find -name '*.sls' ! -exec grep -qF -e '{{' -e '{%' -e '{#' {} \; -print0; fi | \
			xargs -0 yamllint -s
