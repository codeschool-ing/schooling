#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of tech-support, as a script that produces them.
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
# sla.py, written into ana's home on host. No guest is needed: the lesson's
# one program is arithmetic about dates.
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
cat > ~/sla.py <<'SLA'
import sys
from datetime import datetime, timedelta
OPEN, CLOSE = 8, 18           # the service desk's hours
WORKDAYS = range(0, 5)        # Monday to Friday; datetime counts Monday as 0
def deadline(start, hours):
    t, left = start, timedelta(hours=hours)
    while left:
        if t.weekday() not in WORKDAYS or t.hour >= CLOSE:
            t = (t + timedelta(days=1)).replace(hour=OPEN, minute=0)
        elif t.hour < OPEN:
            t = t.replace(hour=OPEN, minute=0)
        else:
            step = min(left, t.replace(hour=CLOSE, minute=0) - t)
            t, left = t + step, left - step
    return t
start = datetime.strptime(sys.argv[1], "%Y-%m-%d %H:%M")
hours = float(sys.argv[2])
print(f"{start:%a %d/%m %H:%M} + {hours:g} h -> {deadline(start, hours):%a %d/%m %H:%M}")
SLA

block runs
on host 'python3 sla.py "2026-09-24 09:00" 8'
on host 'python3 sla.py "2026-09-25 16:30" 4'
on host 'python3 sla.py "2026-09-26 10:00" 1'
on host 'python3 sla.py "2026-09-25 17:59" 0.25'

rm -f ~/sla.py
