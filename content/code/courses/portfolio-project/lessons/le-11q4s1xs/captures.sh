#!/usr/bin/env bash
# Lesson 12 of portfolio-project: tests that earn their keep.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
# THE LAB IS TWO MACHINES. laptop is where ana writes the project; srv is the
# server she deploys it to. Both run Ubuntu 24.04 and share a private network
# (laptop is 10.20.0.10, srv is 10.20.0.20), and ana's key on laptop opens her
# account on srv. A line that starts with ana@laptop ran on laptop, and one that
# starts with ana@srv ran on srv, reached with ssh. The path after the colon is
# the directory the command ran in.
#
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the project's history, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh      # on laptop
#
# The project is loanbook, built step by step by lab.sh with the dates written
# there; `lab stage N` rebuilds ~/loanbook at step N, quietly.
#
# Both machines are containers (systemd-nspawn) on the computer that recorded
# the course, and srv's /etc/containers/containers.conf turns off the pids limit
# a container inside a container cannot have. Nothing a lesson shows depends
# on it.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - ~/loanbook is rebuilt at step 20; then at step 12 with only step 13's test
#     written (lab.sh writes step 13 and app.py is restored), and then step 13's
#     app.py written too; then at step 20 again.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3.12, git 2.43, Podman 4.9 and Caddy 2.6,
# TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
lab() { bash /var/tmp/lab.sh "$@" >/dev/null 2>&1; }
# on MACHINE DIR 'command': what ana typed at her prompt, in DIR (relative to
# her home, "~" for the home itself), on laptop or on srv through ssh, and
# everything it printed.
on() {
  local h=$1 d=$2; shift 2
  local shown=$([ "$d" = "~" ] && echo "~" || echo "~/$d")
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd $HOME/$d")
  printf 'ana@%s:%s$ %s\n' "$h" "$shown" "$*"
  if [ "$h" = laptop ]; then ($cd && bash -c "$*") 2>&1 || true
  else ssh srv "$cd && $*" 2>&1 || true; fi
}
# The same, not shown: the lab's own housekeeping.
quiet() {
  local h=$1 d=$2; shift 2
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd $HOME/$d")
  if [ "$h" = laptop ]; then ($cd && bash -c "$*") >/dev/null 2>&1 || true
  else ssh srv "$cd && $*" >/dev/null 2>&1 || true; fi
}
block() { printf '##### %s\n' "$1"; }

lab stage 20
block suite
on laptop loanbook 'python3 -m unittest -v'
lab stage 12
bash /var/tmp/lab.sh write 13 >/dev/null 2>&1
quiet laptop loanbook 'git restore app.py'
block red
on laptop loanbook 'git diff --stat'
on laptop loanbook 'python3 -m unittest'
bash /var/tmp/lab.sh write 13 >/dev/null 2>&1
block green
on laptop loanbook 'git diff app.py'
on laptop loanbook 'python3 -m unittest'
lab stage 20
block bite
on laptop loanbook "sed -i '/CREATE UNIQUE INDEX/,/WHERE returned_on IS NULL;/d' app.py"
on laptop loanbook 'git diff --stat'
on laptop loanbook 'python3 -m unittest'
on laptop loanbook 'git restore app.py'
