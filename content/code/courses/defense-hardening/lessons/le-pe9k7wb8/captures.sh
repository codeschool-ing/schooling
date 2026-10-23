#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson uses admin (which builds
# and serves the firm's packages), desk (the first ring) and web (the second).
# ana@admin is ana on admin; root@web is the administrator there.
#
# What is STAGED rather than typed: nothing. The two package versions, the
# repository and its web server are built by the commands shown.
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
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab up dns desk trap >/dev/null 2>&1

lab up admin desk web >/dev/null 2>&1

block build
on admin "mkdir -p ~/repo && for v in 1.0 1.1; do
  d=~/pkg/jatoba-health_\$v
  mkdir -p \$d/DEBIAN \$d/usr/bin
  printf 'Package: jatoba-health\nVersion: %s\nArchitecture: all\nMaintainer: Jatoba IT <ti@jatoba.example>\nDepends: curl\nDescription: checks that the client portal answers\n' \$v > \$d/DEBIAN/control
  printf '#!/bin/sh\necho \"jatoba-health %s\"\ncurl -s -o /dev/null -w \"portal %%{http_code}\\\\n\" http://web/healthz\n' \$v > \$d/usr/bin/jatoba-health
  chmod 755 \$d/usr/bin/jatoba-health
  dpkg-deb --root-owner-group --build \$d ~/repo/
done"
on admin 'cat ~/pkg/jatoba-health_1.1/usr/bin/jatoba-health'

block index
on admin 'cd ~/repo && apt-ftparchive packages . > Packages && apt-ftparchive -o APT::FTPArchive::Release::Origin=Jatoba -o APT::FTPArchive::Release::Label=Jatoba release . > Release && ls'
root admin 'systemd-run --unit=repo --uid=ana --working-directory=/home/ana/repo python3 -m http.server 8000; sleep 1; systemctl is-active repo'

block sources
root desk 'mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list'
root desk 'apt-get update 2>&1 | tail -2; apt-cache policy jatoba-health'

block install
root web 'mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list; apt-get update -q >/dev/null'
on admin 'for h in desk web; do ssh $h "sudo apt-get install -y -q jatoba-health=1.0 >/dev/null 2>&1; jatoba-health"; done'

block ring1
on admin 'ssh desk "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^(Preparing|Unpacking|Setting)\"; jatoba-health"'

block ring2
on admin 'ssh web "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^Setting\"; jatoba-health"'
on admin 'for h in desk web; do printf "%s " $h; ssh $h "dpkg-query -W jatoba-health"; done'

block rollback
on admin 'ssh desk "sudo apt-get install -y -q --allow-downgrades jatoba-health=1.0 2>&1 | grep -E \"^(Unpacking|Setting)|downgrad\"; jatoba-health"'
on admin 'ssh desk "grep jatoba-health /var/log/dpkg.log | grep -E \" (install|upgrade) \""'

block unattended
root web 'apt-get install -y -q --allow-downgrades jatoba-health=1.0 >/dev/null 2>&1; dpkg-query -W jatoba-health'
root web "printf 'Unattended-Upgrade::Origins-Pattern { \"origin=Jatoba\"; };\n' > /etc/apt/apt.conf.d/51jatoba; cat /etc/apt/apt.conf.d/51jatoba /etc/apt/apt.conf.d/20auto-upgrades"
root web 'unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Allowed origins|Packages that will be upgraded|All upgrades)"'

block hold
root web 'apt-mark hold jatoba-health; apt-mark showhold'
root web 'apt-get -s upgrade 2>&1 | grep -A1 "kept back"'
root web 'unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Packages that will be upgraded|No packages found)"'
