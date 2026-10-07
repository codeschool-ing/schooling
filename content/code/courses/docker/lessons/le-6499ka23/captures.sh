#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: golang:1.25 is pulled before the first command.
# ~/shelf is rebuilt here from the-project.md, every file read out of the
# lesson's own fences, so what the student pastes is what was built; vendor/
# is copied from the lab's (lab.sh made it with `go mod vendor` from the same
# go.mod and go.sum), because a container here cannot download it. The commit
# is ana's, unsigned, and the transcript shows its author and subject rather
# than its hash: the ~/shelf every other lesson starts from is lab.sh's commit,
# made by root with the recording machine's own git configuration, and its
# hash is not one a student's commit could ever have. The Dockerfiles, the .dockerignore and the .env are
# written by `put` and shown in full. The 300 MB dump is random bytes made by
# `head`, standing in for a database export somebody left in the project.
# Build timings, ids and log timestamps are this run's.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, BuildKit, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25"
. "$(dirname "$0")/../../capture.sh"
MD="$COURSE/lessons/le-6499ka23/the-project.md"
quiet 'rm -rf ~/shelf && mkdir ~/shelf'
cd shelf
for f in main.go postgres.go main_test.go postgres_test.go; do
  python3 "$COURSE/lab/fences.py" example "$MD" "$f" > "$f" || exit 1
done
python3 "$COURSE/lab/fences.py" block "$MD" 'module example.com/shelf' > go.mod || exit 1
python3 "$COURSE/lab/fences.py" block "$MD" "$(head -1 /opt/docker-lab/shelf/go.sum)" > go.sum || exit 1
cp -r /opt/docker-lab/shelf/vendor vendor || exit 1
block commit
run 'git init -q -b main && git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "shelf: the catalogue over HTTP" && git log --format="%an <%ae>: %s"'

block project
run 'ls -A'
put Dockerfile <<'DF'
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
EXPOSE 8080
CMD ["shelf"]
DF
block build
run 'docker build -t shelf:dev .'
block run
run 'docker run -d --name shelf -p 127.0.0.1:8080:8080 shelf:dev'
quiet 'sleep 1'
run 'curl -s localhost:8080/books | jq -c ".[]"'
run 'curl -s localhost:8080/health'
block size
run 'docker image ls shelf'
block stop-exec
run 'time docker stop shelf'
run 'docker logs shelf'

put Dockerfile.shell <<'DF'
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
EXPOSE 8080
CMD shelf
DF
block build-shell
run 'docker build -q -f Dockerfile.shell -t shelf:shell-form .'
run 'docker run -d --name shell-form shelf:shell-form'
quiet 'sleep 1'
block top-shell
run 'docker top shell-form -o pid,ppid,args'
block stop-shell
run 'time docker stop shell-form'
run 'docker logs shell-form'

put ./Dockerfile <<'DF'
FROM golang:1.25
ARG VERSION=dev
WORKDIR /src
COPY . .
RUN go build -ldflags "-X main.version=${VERSION}" -o /usr/local/bin/shelf .
ENV PORT=8080
EXPOSE 8080
CMD ["shelf"]
DF
block build-arg
run 'docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .'
run 'docker run -d --name v1 -e PORT=9090 -p 127.0.0.1:9090:9090 shelf:1.0.0'
quiet 'sleep 1'
run 'curl -s localhost:9090/version'
run 'docker logs v1'
block env-kept
run 'docker image inspect shelf:1.0.0 --format "{{json .Config.Env}}"'

block clutter
run 'mkdir -p testdata && head -c 300M /dev/urandom > testdata/catalogue-dump.sql'
put .env <<'ENV'
DATABASE_URL=postgres://shelf:s3cret-from-ana@db:5432/shelf
ENV
run 'du -sh .git vendor testdata'
block build-fat
run 'docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"'
block inside-fat
run 'docker run --rm shelf:dev ls -a /src'
run 'docker run --rm shelf:dev cat /src/.env'

put .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
block build-lean
run 'docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"'
run 'docker run --rm shelf:dev ls -a /src'
