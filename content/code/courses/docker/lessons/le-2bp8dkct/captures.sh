#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# postgres:17 is NOT pulled beforehand, so its download is in the first
# transcript, through the lab's registry mirror (lesson 6). postgres:16 and
# redis:8 are. The psql on the host is Ubuntu's postgresql-client package,
# which the lab machine already had; the database password is a lab value.
# The timings are whatever this run took. The second transcript catches
# PostgreSQL's image between its first-time setup and its real start, which
# takes about a second here; on a much faster machine the psql in it could
# connect instead of failing.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="postgres:16 redis:8"
. "$(dirname "$0")/../../capture.sh"
ready() { for _ in $(seq 60); do docker exec "$1" pg_isready -U postgres -q 2>/dev/null && return; sleep 1; done; }

block pull
run 'docker pull postgres:17'
block image-config
run 'docker image inspect postgres:17 --format "{{json .Config.Entrypoint}} {{json .Config.Cmd}}"'
run 'docker image inspect postgres:17 --format "{{json .Config.ExposedPorts}}"'

put initdb/01-schema.sql <<'SQL'
CREATE TABLE books (
    id     serial PRIMARY KEY,
    title  text NOT NULL,
    author text NOT NULL
);
INSERT INTO books (title, author) VALUES
    ('The Left Hand of Darkness', 'Ursula K. Le Guin'),
    ('Dom Casmurro', 'Machado de Assis');
SQL
block run
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17'
block lying-ready
run 'time until docker exec db pg_isready -U postgres -q; do sleep 0.2; done'
run 'PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"'
block real-ready
run 'time until docker exec db pg_isready -h 127.0.0.1 -U postgres -q; do sleep 0.2; done'
run 'PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"'
block logs
run 'docker logs db 2>&1 | grep -E "initdb.d/|init process complete|ready to accept connections"'
block again
run 'docker rm -f db'
run 'docker run -d --name db -e POSTGRES_PASSWORD=other -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17'
ready db
run 'docker logs db 2>&1 | grep -E "Skipping|ready to accept"'
run 'PGPASSWORD=other psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"'
run 'PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"'

block side-by-side
run 'docker run -d --name db16 -e POSTGRES_PASSWORD=lab-only -p 127.0.0.1:5416:5432 postgres:16'
ready db16
run 'PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5416 -U postgres -tAc "SHOW server_version"'
run 'PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5432 -U postgres -d shelf -tAc "SHOW server_version"'
block redis
run 'docker run -d --name cache redis:8'
quiet 'sleep 1'
run 'docker exec cache redis-cli PING'
run 'docker exec cache redis-cli SET opening-hours "Mon-Fri 9-18"'
run 'docker exec cache redis-cli GET opening-hours'
