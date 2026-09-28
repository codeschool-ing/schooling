#!/usr/bin/env bash
# Lesson 15 of portfolio-project: a deploy that stays up.
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
#   - ~/loanbook is rebuilt at step 20 on laptop (lab.sh).
#   - srv already has Podman 4.9 and Caddy 2.6 installed from Ubuntu's packages,
#     with Caddy disabled, and the python:3.12-slim image already pulled: srv has
#     no route to the internet, so the pull was done before the lab was cut off.
#   - A reboot was not recorded: the lab machines are containers, and one that
#     reboots does not come back on its own.
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
block remote
on srv '~' 'git init -q --bare loanbook.git'
on laptop loanbook 'git remote add srv srv:loanbook.git'
on laptop loanbook 'git push -q srv main --tags'
on srv '~' 'git clone -q loanbook.git && git -C loanbook log --oneline -1'
block build
on srv loanbook 'cat Containerfile'
on srv loanbook 'sudo podman build -t loanbook .'
block unit
on srv loanbook 'cat deploy/loanbook.container'
on srv loanbook 'sudo cp deploy/loanbook.container /etc/containers/systemd/'
on srv loanbook 'sudo systemctl daemon-reload'
on srv loanbook 'sudo systemctl start loanbook'
sleep 3
on srv loanbook 'systemctl status loanbook --no-pager | head -6'
on srv loanbook 'curl -s 127.0.0.1:8000/healthz'
echo
block seed
on srv loanbook 'sudo podman exec systemd-loanbook python3 seed.py'
block caddy
on srv loanbook 'cat deploy/Caddyfile'
on srv loanbook 'sudo cp deploy/Caddyfile /etc/caddy/Caddyfile'
on srv loanbook 'sudo systemctl enable --now caddy'
sleep 4
block untrusted
on laptop '~' "echo '10.20.0.20 loans.lab' | sudo tee -a /etc/hosts"
on laptop '~' 'curl -sS https://loans.lab/healthz'
block trust
on laptop '~' 'ssh srv sudo cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt > lab-root.crt'
on laptop '~' 'openssl x509 -in lab-root.crt -noout -subject -enddate'
on laptop '~' 'sudo cp lab-root.crt /usr/local/share/ca-certificates/loans-lab-root.crt'
on laptop '~' 'sudo update-ca-certificates'
on laptop '~' 'curl -sS https://loans.lab/healthz'
echo
on laptop '~' 'curl -sS https://loans.lab/api/items | python3 -m json.tool | head -12'
block health
on srv '~' 'sudo podman healthcheck run systemd-loanbook && echo healthy'
on srv '~' "sudo podman inspect --format '{{.State.Health.Status}}' systemd-loanbook"
block restart
on srv '~' 'systemctl show -p NRestarts loanbook'
on srv '~' 'sudo podman kill systemd-loanbook'
sleep 6
on srv '~' 'systemctl show -p NRestarts loanbook'
on srv '~' 'systemctl is-active loanbook'
on laptop '~' 'curl -sS https://loans.lab/healthz'
echo
on laptop '~' "curl -sS https://loans.lab/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), \"items\")'"
block boot
on srv '~' 'systemctl is-enabled loanbook caddy'
