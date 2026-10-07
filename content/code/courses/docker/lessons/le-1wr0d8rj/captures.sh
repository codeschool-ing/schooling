#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command, and the files ana works on are written by `put`, shown in full in
# the lesson. Nothing in this lesson reaches the network from inside a
# container, which on the lab machine would fail (lab.sh says why).
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="mikefarah/yq:4 koalaman/shellcheck:stable hadolint/hadolint:latest python:3.12-slim python:3.13-slim amazon/aws-cli:latest"
. "$(dirname "$0")/../../capture.sh"
mkdir -p ops && cd ops

put config.yaml <<'YAML'
service: shelf
database:
  host: db
  port: 5432
  pool: 10
features:
  - search
  - loans
YAML
block yq
run 'docker run --rm -v "$PWD":/work -w /work mikefarah/yq:4 ".database.port" config.yaml'
run 'cat config.yaml | docker run --rm -i mikefarah/yq:4 ".features | length"'

put backup.sh <<'SH'
#!/bin/sh
target=$1
tar -czf $target/backup.tar.gz /srv/data
echo "saved to $target"
SH
block not-installed
run 'which shellcheck hadolint; echo "exit status $?"'
block shellcheck
run 'docker run --rm -v "$PWD":/mnt koalaman/shellcheck:stable /mnt/backup.sh'

put Dockerfile <<'DF'
FROM python:latest
RUN apt-get update && apt-get install curl
COPY . /app
CMD python /app/main.py
DF
block hadolint
run 'docker run --rm -i hadolint/hadolint hadolint --no-color - < Dockerfile'

put stats.py <<'PY'
import copy
from dataclasses import dataclass

@dataclass(frozen=True)
class Loan:
    book: str
    days: int

first = Loan("Dom Casmurro", 14)
renewed = copy.replace(first, days=28)
print(renewed)
PY
block python
run 'docker run --rm -v "$PWD":/work -w /work python:3.13-slim python stats.py'
run 'docker run --rm -v "$PWD":/work -w /work python:3.12-slim python stats.py'

block owner
run 'docker run --rm -v "$PWD":/work -w /work python:3.13-slim python -c "open('"'"'out.txt'"'"', '"'"'w'"'"').write('"'"'x'"'"')"'
run 'ls -l out.txt'
run 'rm -f out.txt'
run 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work -w /work python:3.13-slim python -c "open('"'"'out.txt'"'"', '"'"'w'"'"').write('"'"'x'"'"')"'
run 'ls -l out.txt'

block wrapper
run 'yq() { docker run --rm -i -v "$PWD":/work -w /work mikefarah/yq:4 "$@"; }'
run 'yq ".service" config.yaml'
run 'type yq'
block outside
run 'echo "x: 1" > ../other.yaml'
run 'yq ".x" ../other.yaml'
block overhead
run 'time yq --version'
put tools.sh <<'SH'
# Tools that run in containers. Source this file from ~/.bashrc to keep them.
yq() {
  docker run --rm -i \
    -v "$PWD":/work -w /work \
    --user "$(id -u):$(id -g)" \
    mikefarah/yq:4 "$@"
}

shellcheck() {
  docker run --rm -v "$PWD":/mnt -w /mnt \
    koalaman/shellcheck:stable "$@"
}
SH
block sourced
run '. ./tools.sh'
run 'yq ".database.pool" config.yaml'
run 'shellcheck --severity=warning backup.sh; echo "exit status $?"'
block aws
run 'docker run --rm amazon/aws-cli:latest --version'
