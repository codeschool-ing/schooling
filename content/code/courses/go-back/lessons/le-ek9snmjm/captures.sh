#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice is
# assembled from lessons 1 to 16 by ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - Docker Engine was installed on the lab machine from Docker's apt
#     repository, by the commands section 02 shows, before this script ran.
#     The lab machine does not boot with systemd, so this script starts the
#     daemon itself when it is not running; on the student's machine the
#     package does that.
#   - ana is taken out of the docker group at the start, so that section 03
#     can show the refusal, and put in with the usermod section 03 shows; each
#     command runs in a new login, which is what logging out and in again gives
#     the student.
#   - the last command of section 03 points docker at a socket nobody
#     listens on, which is how a stopped daemon looks; the lab's daemon is
#     never stopped.
#   - the image gcr.io/distroless/static-debian12:nonroot had been pulled
#     before; section 06's pull finds it up to date.
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     has ana put it in ~/.profile; the database is dropped and made again,
#     migrated, and boxoffice's generators run, as lessons 9 and 10 leave the
#     project. The manager's token file of lesson 14 is made again.
#   - the containers and images this script makes are removed at its start,
#     so every run begins from the same place.
# Sizes, image ids, container ids and timestamps are whatever the run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# Docker Engine 29.8.2, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
if ! docker info >/dev/null 2>&1; then
  setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
  for i in $(seq 1 50); do docker info >/dev/null 2>&1 && break; sleep 0.2; done
fi
docker rm -f boxoffice >/dev/null 2>&1 || true
docker rmi -f boxoffice:dynamic boxoffice:v0.16.0 boxoffice:v0.16.0-arm64 >/dev/null 2>&1 || true
gpasswd -d ana docker >/dev/null 2>&1 || true

project 16 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy && rm -rf dist'
quiet . 'mkdir -p ~/.config/boxoffice && (umask 077; openssl rand -hex 16 > ~/.config/boxoffice/manager-token)'

block installed
on . "dpkg-query -W -f '\${Package} \${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
on . 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'

block fails
on . 'docker ps'
on . 'sudo usermod -aG docker $USER'
on . 'id -nG; docker ps'
on . 'DOCKER_HOST=unix:///run/nobody-here.sock docker ps'

block cross
on boxoffice 'go env GOOS GOARCH; go tool dist list | wc -l'
on boxoffice 'for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go build -o dist/try-${t%/*}-${t#*/} . || exit; done; ls -l dist'
on boxoffice 'file dist/try-*'

block cgo
on boxoffice 'go env CGO_ENABLED; ldd dist/try-linux-amd64'
on boxoffice 'CGO_ENABLED=0 go build -o dist/try-static . && file dist/try-static && ldd dist/try-static'

block release
on boxoffice 'CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && ls -l dist/try-static dist/boxoffice-linux-amd64'
on boxoffice 'go version -m dist/boxoffice-linux-amd64 | grep -e "^dist" -e build'
on boxoffice 'DATABASE_URL=postgres:///nowhere?host=/nowhere BOXOFFICE_MANAGER_TOKEN=x ./dist/boxoffice-linux-amd64 2>&1 | head -1'

block dynamic
on boxoffice 'docker pull gcr.io/distroless/static-debian12:nonroot'
on boxoffice 'cp dist/try-linux-amd64 dist/boxoffice-linux-amd64 && docker build -q -t boxoffice:dynamic . && docker run --rm boxoffice:dynamic; echo "exit $?"'

block image
on boxoffice 'CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && docker build -q -t boxoffice:v0.16.0 .'
on boxoffice 'docker image ls | grep -e IMAGE -e boxoffice:v -e distroless'
on boxoffice 'docker run --rm --entrypoint sh boxoffice:v0.16.0; echo "exit $?"'

block run
on . 'docker run --rm boxoffice:v0.16.0; echo "exit $?"'
on . 'docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="$DATABASE_URL" boxoffice:v0.16.0'
sleep 2
on . 'docker logs boxoffice'
on . 'docker rm boxoffice'
block run-again
on . 'docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="postgres://$USER@/boxoffice?host=/var/run/postgresql" -e TZ=America/Sao_Paulo boxoffice:v0.16.0'
sleep 2
on . 'curl -s localhost:8080/events/1'
on . 'docker logs boxoffice'
on . 'time docker stop boxoffice'
quiet . 'docker rm boxoffice'

block arm
on boxoffice 'CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-arm64 . && docker buildx build -q --platform linux/arm64 -t boxoffice:v0.16.0-arm64 --load .'
on boxoffice 'docker image inspect --format "{{.Os}}/{{.Architecture}}" boxoffice:v0.16.0 boxoffice:v0.16.0-arm64'
on boxoffice 'docker run --rm boxoffice:v0.16.0-arm64; echo "exit $?"'
