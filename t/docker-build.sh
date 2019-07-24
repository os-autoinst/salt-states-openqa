FROM=${1:-'opensuse/leap:42.3'}

(
cat << EOF
FROM $FROM

RUN eval \$(cat /etc/os-release) && zypper ar -G http://download.suse.de/ibs/SUSE:/CA/\${PRETTY_NAME// /_}/SUSE:CA.repo
RUN zypper -n in ca-certificates-suse salt-minion
EOF
) | docker build -t openqa-salt-test -
