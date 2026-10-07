#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the two images are pulled before the first
# command, and the script waits, without showing it, for PostgreSQL to accept
# connections before the first psql. Volume names are random hashes Docker
# invents, so a second run prints different ones.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22 postgres:17"
. "$(dirname "$0")/../../capture.sh"
ready() { for _ in $(seq 60); do docker exec "$1" pg_isready -U postgres -q 2>/dev/null && return; sleep 1; done; }

block write
run 'docker run -d --name notes alpine:3.22 sleep 3600'
run 'docker exec notes sh -c "echo first note > /notes.txt"'
run 'docker diff notes'
block stop-start
run 'docker stop notes'
run 'docker ps -a --format "{{.Names}}: {{.Status}}"'
run 'docker start notes'
run 'docker exec notes cat /notes.txt'
block rm
run 'docker rm -f notes'
run 'docker run -d --name notes alpine:3.22 sleep 3600'
run 'docker exec notes cat /notes.txt'

block db-1
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17'
ready db
run 'docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('"'"'Dom Casmurro'"'"', '"'"'Bruno'"'"')" -c "SELECT * FROM loans"'
block db-2
run 'docker rm -f db'
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17'
ready db
run 'docker exec db psql -U postgres -c "SELECT * FROM loans"'
block volumes
run 'docker volume ls'
run 'docker inspect db --format "{{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{end}}"'
block config-volume
run 'docker image inspect postgres:17 --format "{{json .Config.Volumes}}"'
OLD=$(docker volume ls -q | grep -v "$(docker inspect db --format '{{range .Mounts}}{{.Name}}{{end}}')")
block rescue
run 'docker rm -f db'
run "docker run -d --name rescued -e POSTGRES_PASSWORD=lab-only -v $OLD:/var/lib/postgresql/data postgres:17"
ready rescued
run 'docker exec rescued psql -U postgres -c "SELECT * FROM loans"'

block commit
run 'docker exec notes sh -c "echo second note > /notes.txt"'
run 'docker commit notes notes:snapshot'
run 'docker history notes:snapshot'
