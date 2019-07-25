TESTDIR="$(cd "$(dirname "$0")"; pwd)";
docker run -it --rm -v/${TESTDIR}/../openqa:/srv/salt openqa-salt-test:latest salt-call -l debug --local state.apply openqa-trigger-from-ibs
