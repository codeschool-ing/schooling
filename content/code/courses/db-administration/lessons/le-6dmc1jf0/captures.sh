#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts from the server before PostgreSQL is installed, because the lesson
# installs it. apt's own output is not quoted (the machine installs from its
# cache, with no network, so it prints none of the download lines a student
# sees); everything after it is.
#
# STAGED: the container section was recorded with Docker 29.8.2 on the
# recording computer itself rather than inside the server, because that
# section is the alternative to the server: it runs on the student's own
# computer. Its prompt is ana@laptop for that reason. The image is the
# official postgres:16, pulled from Docker Hub on the day.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 3

block installed-nothing
on 'psql --version'

lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql >/dev/null 2>&1'

block after-install
on 'psql --version'
on 'pg_lsclusters'
on 'systemctl status postgresql@16-main --no-pager'

block whoami
on 'psql'
on 'sudo -u postgres psql -c "SELECT current_user, version();"'

block createuser
on 'sudo -u postgres createuser --superuser $USER'
on 'createdb $USER'
printf 'ana@db:~$ psql\n'
printf '#banner\n\\conninfo\nSHOW data_directory;\nSHOW config_file;\n\\q\n' | session

block processes
on 'ps -u postgres -o pid,cmd'

block stopped
on 'sudo systemctl stop postgresql'
lab as 'while pg_lsclusters -h | grep -q online; do sleep 0.2; done; sleep 1'
on 'psql'
on 'pg_lsclusters'
on 'sudo systemctl start postgresql'

block peer
on 'psql -U postgres'

block tcp
on 'psql -h localhost'

# not quoted: proves the two commands in "Starting again" work as printed
lab as 'sudo pg_dropcluster --stop 16 main && sudo pg_createcluster --start 16 main >/dev/null && pg_lsclusters -h' >&2

block container
host() { printf 'ana@laptop:~$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
docker rm -f pg >/dev/null 2>&1; docker volume rm pgdata >/dev/null 2>&1
host 'docker run -d --name pg -e POSTGRES_PASSWORD=change-me -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5433:5432 postgres:16'
sleep 6
host 'docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}  {{.Ports}}"'
host 'docker exec pg psql -U postgres -c "SHOW data_directory;" -c "SHOW config_file;"'
host 'docker logs pg 2>&1 | tail -3'
docker rm -f pg >/dev/null 2>&1; docker volume rm pgdata >/dev/null 2>&1

lab down
