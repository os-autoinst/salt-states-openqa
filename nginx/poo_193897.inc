# See https://progress.opensuse.org/issues/195653 and https://progress.opensuse.org/issues/193897
location ~ "^/api/v1/jobs/[0-9]{20,}" {
    return 413;
}
