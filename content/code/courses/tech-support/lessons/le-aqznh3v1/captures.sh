#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of tech-support, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. The computer is called host
# and runs Ubuntu 24.04 with QEMU and libvirt; every other name is one of its
# guests, a real virtual machine made by lab.sh from Ubuntu's minimal cloud
# image. A line that starts with ana@host ran on the computer itself, and one
# that starts with ana@vm1 ran inside the guest called vm1, reached with ssh.
#
# The computer the lab was recorded on is itself a virtual machine without
# nested virtualisation, so QEMU emulates the guests' processor in software
# (--virt-type qemu). With VT-x or AMD-V, the same commands take kvm.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset; the guests srv1 and pc2, made by lab.sh
# vm; nginx on srv1 with the intranet's one-line page; the knowledge base, a
# folder kb in ana's home with three short articles written for the lesson,
# the intranet one carrying the date 2024-03-11 and the old address
# 10.30.0.200, standing for an article written when the intranet lived there;
# and the rewritten article, written by the script with today's date, before
# the diff shows it. In the lab's office, srv1 has no DNS name, so the
# article looks it up with getent in /etc/hosts, where lab.sh put it.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with QEMU 8.2 and libvirt 10.0, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on MACHINE 'command': what ana typed at her prompt, on host itself or inside
# one of its guests (reached with ssh), and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  if [ "$h" = host ]; then (cd && bash -c "$*") 2>&1 || true
  else ssh "$h" "$*" 2>&1 || true; fi
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() {
  local h=$1; shift
  if [ "$h" = host ]; then sudo bash -c "$*" >/dev/null 2>&1 || true
  else ssh "$h" "sudo bash -c $(printf %q "$*")" >/dev/null 2>&1 || true; fi
}
block() { printf '##### %s\n' "$1"; }

cd ~
lab reset
lab vm srv1 >/dev/null 2>&1
lab vm pc2 >/dev/null 2>&1
srv=$(awk '$2 == "srv1" {print $1}' /etc/hosts)
quiet srv1 'systemctl enable --now nginx; echo "intranet: welcome" > /var/www/html/index.html'
mkdir -p ~/kb
printf '%s\n' '# Printing from a new computer' '' 'Add the office printer with lpadmin, then set it as the default.' > ~/kb/printing-from-a-new-computer.md
printf '%s\n' '# Shared folder is full' '' 'See the runbook for the export log.' > ~/kb/shared-folder-full.md
printf '%s\n' '# Intranet on a new computer' '' 'Add the intranet to the hosts file:' '' '    echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts' '' 'Then open http://intranet/ in the browser.' '' 'Last reviewed: 2024-03-11' > ~/kb/intranet-on-a-new-computer.md

block search
on host 'ls kb; grep -rl intranet kb'
on host 'cat kb/intranet-on-a-new-computer.md'

block follow
on pc2 'echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts'
on pc2 'curl -sS -m 10 http://intranet/'

block rewrite
cat > ~/kb/intranet-new.md <<ARTICLE
# The intranet does not open on a new computer

Symptom: the browser cannot reach http://intranet/, or curl says
"Could not resolve host: intranet" or "Couldn't connect to server".
Applies to: an office computer set up by hand. Needs: sudo on it.

1. On the computer: getent hosts intranet
   Expected: nothing, or an old address to replace.
2. On your own computer, srv1's current address: getent hosts srv1
3. On the computer, put the line "<that address> intranet" in /etc/hosts,
   replacing any intranet line already there.
4. On the computer: curl -sS http://intranet/
   Expected: intranet: welcome

If step 4 fails, escalate to level 2 with the output of steps 1, 2 and 4.

Owner: service desk. Last reviewed: $(date +%F), followed on pc2.
ARTICLE
on host 'diff -u kb/intranet-on-a-new-computer.md kb/intranet-new.md'

block verify
on pc2 'getent hosts intranet'
on host 'getent hosts srv1'
on pc2 "sudo sed -i 's/^.* intranet$/$srv intranet/' /etc/hosts && grep intranet /etc/hosts"
on pc2 'curl -sS -m 10 http://intranet/'
quiet host 'mv /home/ana/kb/intranet-new.md /home/ana/kb/intranet-on-a-new-computer.md'

lab down >/dev/null 2>&1
rm -rf ~/kb
