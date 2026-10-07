#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# THREE KINDS OF EVIDENCE, AND WHAT EACH ONE IS:
#   - shipquote's GitHub Actions workflow (step 8 of ../../lab.sh) was NOT run
#     on GitHub: this lab has no repository there. It is checked with
#     actionlint 1.7.7, a static checker, and the lesson says so.
#   - shipquote's .gitlab-ci.yml WAS run, on this machine, by gitlab-ci-local
#     4.76.0, an open-source emulator of GitLab's runner that starts the same
#     container images in Docker 29.8.2. It is not GitLab. The images came from
#     mirror.gcr.io and were retagged with their Docker Hub names, and the
#     emulator was given the lab's HTTPS proxy and its CA certificate as
#     variables and a volume so pip could reach PyPI; neither appears in the
#     YAML, and on GitLab neither would be needed. Its output is cut to the
#     lines the section reads, with grep, as shown.
#   - the runs of THIS repository's workflow were read from GitHub's public
#     REST API on the date below, by run id, so they are records GitHub kept
#     and not anything this script started.
#
# Both workflow files are shown whole, in "anatomy" and "gitlab-ci", and
# `../../lab.sh shown` fails this script before its first block if either is
# not the file ../../lab.sh wrote at step 8.
#
# What is STAGED rather than typed, and not shown in the lesson: the project
# at step 8 in /home/ana/shipquote with a remote named origin pointing at an
# address nobody answers (the emulator reads it for CI_PROJECT_* variables);
# and in "actionlint-typo" the two typos the section shows, made with sed and
# undone with git checkout.
#
# Recorded 2026-10-06 on Ubuntu 24.04, TZ=America/Sao_Paulo, as root with
# HOME=/home/ana so the paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
REPO=$(cd "$HERE/../../../../../.." && pwd)
ACTIONLINT=${ACTIONLINT:-/tmp/claude-0/bin/actionlint}
GCL=${GCL:-/tmp/claude-0/gcl/node_modules/.bin/gitlab-ci-local}
export PATH="$(dirname "$ACTIONLINT"):$(dirname "$GCL"):$PATH"
bash "$LAB" stage 8 >/dev/null
bash "$LAB" shown "$HERE" || exit 1
cd "$HOME/shipquote" || exit 1
git remote add origin https://gitlab.example.com/livraria/shipquote.git
git update-ref refs/remotes/origin/main HEAD
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git config user.name "Ana Lima"; git config user.email ana@example.org
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
api() { printf 'ana@laptop:~$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
export A=https://api.github.com/repos/codeschool-ing/schooling/actions

block actionlint-ok
run 'actionlint; echo "exit status $?"'

block actionlint-typo
sed -i 's/python-version: \${{ matrix.python }}/python-version: ${{ matrix.pyton }}/' .github/workflows/ci.yml
sed -i '0,/cache-dependency-path/s//cache-dependancy-path/' .github/workflows/ci.yml
run 'actionlint; echo "exit status $?"'
git checkout -q .github/workflows/ci.yml

block check-actions
(cd "$REPO" && printf 'ana@laptop:~/schooling$ %s\n' 'go run ./tools/check-actions -offline' &&
  GOTOOLCHAIN=go1.25.0 go run ./tools/check-actions -offline 2>&1)

block run
api 'echo $A'
api 'curl -s $A/runs/37488673045 | jq -r "[.name, .event, .head_sha[:7], .conclusion, .run_started_at, .updated_at] | @tsv"'
api 'curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | [.name, .conclusion, .started_at, .completed_at] | @tsv"'

block steps
api 'curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | [.number, .name, ((.completed_at | fromdate) - (.started_at | fromdate))] | @tsv" | sort -t$'"'"'\t'"'"' -k3 -nr | head -5'

block failed
api 'curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"'
api 'curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | select(.number >= 10 and .number <= 16) | [.number, .name, .conclusion] | @tsv"'

block skipped
api 'curl -s $A/runs/35432460022 | jq -r "[.event, .head_branch, .conclusion] | @tsv"'
api 'curl -s $A/runs/35432460022/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"'

block cancelled
api 'curl -s "$A/workflows/ci.yml/runs?branch=claude/wonderful-cray-nrgjb2&created=2026-09-19&per_page=8" | jq -r ".workflow_runs[] | [.id, .conclusion, .run_started_at, .updated_at] | @tsv"'

block gitlab
run 'gitlab-ci-local --list'
gitlab-ci-local --helper-image mirror.gcr.io/firecow/gitlab-ci-local-util:latest \
  --pull-policy if-not-present --network host \
  --volume /root/.ccr/ca-bundle.crt:/etc/lab-ca.crt:ro \
  --variable "HTTPS_PROXY=$HTTPS_PROXY" --variable PIP_CERT=/etc/lab-ca.crt \
  > gcl.log 2>&1
printf 'ana@laptop:~/shipquote$ %s\n' 'gitlab-ci-local > gcl.log 2>&1'
run 'grep -E "^ (PASS|FAIL)|pipeline finished" gcl.log'
run 'grep -E "^coverage .*(Combined|TOTAL)" gcl.log'
rm -f gcl.log
