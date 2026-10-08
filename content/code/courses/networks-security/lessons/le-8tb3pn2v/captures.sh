#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset; probe, a small command lab.sh installs
# that tries a TCP connection and says open, refused or blocked; baseline.nft,
# written to fw's home by lab.sh, which this lesson reads and loads.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/nslab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset

block flat
on remote 'probe db:5432 app:22 app:8080 laptop:22 www:443'

block baseline
root fw 'cat baseline.nft'
root fw 'nft -f baseline.nft'

block matrix
on remote 'probe www:443 www:80 dns:53 app:8080 db:5432 laptop:22'
on laptop 'probe www:443 app:8080 db:5432 app:22 remote:443'
on admin 'probe app:22 db:22 www:22 app:8080 db:5432'
on www 'probe app:8080 app:22 db:5432 laptop:22 remote:443'

block dns-udp
on remote 'dig +short @192.0.2.53 www.example.com'
on laptop 'dig +short @192.0.2.53 db.corp.example.com'

block blast
on www 'probe app:8080 db:5432 app:22 laptop:22 admin:22 remote:80 remote:443'
root fw 'nft list ruleset | grep -c "iifname \"eth1\""'

block segment
on app 'probe db:5432 db:22'
on laptop 'probe desk:22'
quiet desk 'setsid socat TCP-LISTEN:445,bind=192.168.10.21,fork,reuseaddr SYSTEM:"echo desk share" </dev/null >/dev/null 2>&1 &'
sleep 0.5
on laptop 'probe desk:445'

block comments
root fw 'nft list chain ip filter forward | grep -E "comment|policy"'
