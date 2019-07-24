TESTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
docker run -it --rm -v/${TESTDIR}/../openqa:/srv/salt openqa-salt-test:latest salt-call -l debug --local state.apply openqa-trigger-from-ibs
