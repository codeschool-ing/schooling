#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: golang:1.25 is pulled before the first command,
# the build cache starts empty, and the Dockerfiles, the .dockerignore and the
# two edits ana makes (a `sed` on main.go and a new README.md) are in the
# script. The build output is filtered with awk to the lines that name a step
# of the Dockerfile and say whether it ran or came from the cache; the awk is in
# the command.
# Timings are this run's, on a machine with four processors.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, BuildKit, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25"
. "$(dirname "$0")/../../capture.sh"
cd shelf
steps="awk '/^#[0-9]+ \\[(stage-0 )?[0-9]/ {n[\$1]=1; print; next} (\$1 in n) && /DONE|CACHED/'"

put .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
put Dockerfile <<'DF'
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
DF
block first
run 'time docker build -q -t shelf:dev .'
block history
run 'docker history shelf:dev'
block same
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"
block edit
run 'sed -i "s/listening on/serving on/" main.go'
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"
block readme
run 'echo "# shelf" > README.md'
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"

put ./Dockerfile <<'DF'
FROM golang:1.25
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
DF
block ordered-first
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"
block ordered-edit
run 'sed -i "s/serving on/listening on/" main.go'
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"
block ordered-readme
run 'echo "A bookshop catalogue over HTTP." >> README.md'
run "time docker build --progress=plain -t shelf:dev . 2>&1 | $steps"

put ././Dockerfile <<'DF'
FROM golang:1.25
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o /usr/local/bin/shelf .
CMD ["shelf"]
DF
block mount-first
run 'time docker build -q -t shelf:mount .'
block mount-edit
run 'sed -i "s/listening on/serving on/" main.go'
run "time docker build --progress=plain -t shelf:mount . 2>&1 | $steps"
block df
run 'docker buildx du | tail -4'
