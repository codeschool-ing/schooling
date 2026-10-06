#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images are pulled before the first command,
# and the script waits, without showing it, for PostgreSQL to accept
# connections before each psql. ~/site is a directory the script makes for
# the bind-mount examples.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22 postgres:17"
. "$(dirname "$0")/../../capture.sh"
ready() { for _ in $(seq 60); do docker exec "$1" pg_isready -U postgres -q 2>/dev/null && return; sleep 1; done; }

block create
run 'docker volume create pgdata'
run 'docker volume inspect pgdata'
block db-1
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17'
ready db
run 'docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('"'"'Dom Casmurro'"'"', '"'"'Bruno'"'"')"'
block db-2
run 'docker rm -f db'
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17'
ready db
run 'docker exec db psql -U postgres -c "SELECT * FROM loans"'
block vol-ls
run 'docker volume ls'
block backup
run 'docker run --rm -v pgdata:/data:ro -v "$PWD":/backup alpine:3.22 tar -czf /backup/pgdata.tar.gz -C /data .'
run 'ls -l pgdata.tar.gz'

block bind
run 'mkdir site && echo "<h1>Opening hours</h1>" > site/index.html'
run 'docker run -d --name web -v "$PWD/site":/srv alpine:3.22 sleep 3600'
run 'docker exec web cat /srv/index.html'
run 'echo "<p>Mon-Fri 9-18</p>" >> site/index.html'
run 'docker exec web cat /srv/index.html'
block bind-owner
run 'docker exec web sh -c "echo generated > /srv/report.txt"'
run 'ls -l site'
run 'rm site/report.txt'
block bind-user
run 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/site":/srv alpine:3.22 sh -c "echo generated > /srv/report.txt"'
run 'ls -l site'
block bind-hides
run 'docker run --rm -v "$PWD/site":/etc alpine:3.22 ls /etc'
block readonly
run 'docker run --rm -v "$PWD/site":/srv:ro alpine:3.22 sh -c "echo x >> /srv/index.html"'
block mount-syntax
run 'docker run --rm --mount type=bind,source="$PWD/missing",target=/srv alpine:3.22 true'
run 'docker run --rm -v "$PWD/missing":/srv alpine:3.22 true; ls -ld missing'
block tmpfs
run 'docker run --rm --tmpfs /scratch:size=16m alpine:3.22 sh -c "df -h /scratch; dd if=/dev/zero of=/scratch/big bs=1M count=32"'
block tmpfs-default
run 'docker run --rm --tmpfs /scratch alpine:3.22 df -h /scratch'
