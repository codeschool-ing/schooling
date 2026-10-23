#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by ../../lab.sh from
# the hostlab.sh lesson 1 shows: web and trap are started fresh. A line that
# starts with ana@web ran on the machine called web, as ana.
#
# What is STAGED rather than typed:
# - relatorio.sh and 20-sandbox.conf are written into ana's home on web from
#   this lesson's own Markdown, byte for byte as the copy button hands them
#   over: the student pastes them. relatorio.sh is the lesson's own harmless
#   "suspicious file": it lists the names in ~/.ssh, tries to leave a file in
#   /etc and tries to reach trap; nothing in it reads or sends any secret.
# - trap is started only so that its address answers; nothing listens on
#   port 8443 there.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
put() {   # put HOST USER PATH FILE: write a file the lesson shows onto a machine
  python3 /var/tmp/dh/tools/fromlesson.py "$here" "$4" | lab exec "$1" "$2" "cat > $3"
}

lab up web trap >/dev/null 2>&1
for f in relatorio.sh 20-sandbox.conf; do put web ana "/home/ana/$f" "$f"; done
lab exec web ana 'mkdir -p ~/.ssh' >/dev/null 2>&1

block plain
on web 'ls ~/.ssh; ls /etc/relatorio-was-here 2>&1'

block sandbox
on web 'sudo systemd-run -q --wait --pipe --uid=ana -p ProtectHome=tmpfs -p BindReadOnlyPaths=/home/ana/relatorio.sh -p ProtectSystem=strict -p PrivateNetwork=yes -p PrivateTmp=yes -p NoNewPrivileges=yes bash /home/ana/relatorio.sh'

block trace
on web 'sudo systemd-run -q --wait --pipe --uid=ana -p ProtectHome=tmpfs -p BindReadOnlyPaths=/home/ana/relatorio.sh -p ProtectSystem=strict -p PrivateNetwork=yes -p PrivateTmp=yes strace -f -qq -e trace=statx,openat,connect -e signal=none bash /home/ana/relatorio.sh 2>&1 | grep -E "= -1 E" | grep -E "\.ssh|relatorio-was|inet_addr"'

block firejail
on web 'firejail --quiet --net=none --whitelist=~/relatorio.sh --read-only=/etc bash relatorio.sh'

block score
on web 'systemd-analyze security portal | tail -1'
on web 'systemd-analyze security portal | grep -E "PrivateNetwork=|ProtectHome=|ProtectSystem=|CapabilityBoundingSet=~CAP_SYS_ADMIN"'

block harden
on web 'sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 20-sandbox.conf /etc/systemd/system/portal.service.d/'
on web 'sudo systemctl daemon-reload && sudo systemctl restart portal && sleep 1 && curl -s http://localhost/'
on web 'systemd-analyze security portal | tail -1'
