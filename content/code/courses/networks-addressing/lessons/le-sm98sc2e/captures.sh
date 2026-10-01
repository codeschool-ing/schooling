#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana       # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh    # the lab, beside course.json
#   sudo bash captures.sh
#
# The lab is lab.sh's "lag" scenario: two switches, sw1 and sw2, joined by two
# cables (e1 and e2 on each side) that start outside both switches; pc1 on
# sw1, and pc2, pc3 and pc4 on sw2. The bundle is the Linux bonding driver in
# 802.3ad mode, which speaks LACP.
#
# Power over Ethernet was NOT run: it is electricity on the pairs of a copper
# cable, and a lab of virtual cables has none. The lesson's PoE numbers are
# the IEEE 802.3 classes, stated as such.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up lag`; the same bundle typed on sw2 as on sw1, shown for
# sw1 only; a wait of ten seconds for LACP to agree on both sides; and, in the
# failure block, cable e1 pulled, which the script does by setting sw2's end
# of it down.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() { local h=$1; shift; printf 'ana@%s:~$ %s\n' "$h" "$*"; lab exec "$h" ana "$*" 2>&1 || true; }
# root HOST 'command': the same at a root prompt, on a device being configured.
root() { local h=$1; shift; printf 'root@%s:~# %s\n' "$h" "$*"; lab exec "$h" root "$*" 2>&1 || true; }
# quiet HOST 'command': the lab's own housekeeping, run as root and not shown.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {  # bgon USER HOST 'command'
  local p='$'; [ "$1" = root ] && p='#'
  printf '%s@%s:~%s %s\n' "$1" "$2" "$p" "$3" > /tmp/bg.out
  lab exec "$2" "$1" "$3" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 2
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }
BOND1='ip link add bond0 type bond mode 802.3ad lacp_rate fast miimon 100 xmit_hash_policy layer2+3'
BOND2='ip link set e1 down && ip link set e2 down'
BOND3='ip link set e1 master bond0 && ip link set e2 master bond0'
BOND4='ip link set bond0 master br0 && ip link set bond0 up'

lab up lag

block apart
root sw1 'ip -br link'
on pc1 'ping -c 1 -W 1 -q 10.20.10.22'

block bundle
root sw1 "$BOND1"; root sw1 "$BOND2"; root sw1 "$BOND3"; root sw1 "$BOND4"
quiet sw2 "$BOND1; $BOND2; $BOND3; $BOND4"
sleep 10
root sw1 'ip -br link'
root sw1 'cat /proc/net/bonding/bond0'
on pc1 'ping -c 2 -q 10.20.10.22'

block hashing
root sw1 'ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"'
on pc1 'for h in 22 23 24; do ping -c 50 -i 0.2 -q 10.20.10.$h | grep transmitted; done'
root sw1 'ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"'
root sw1 'cat /sys/class/net/bond0/bonding/xmit_hash_policy'

block failure
bgon ana pc1 'ping -c 20 -i 0.5 -q 10.20.10.23'
quiet sw2 'ip link set e1 down'
fgon
root sw1 'grep -A3 "Slave Interface" /proc/net/bonding/bond0'
root sw1 'ip -br link show bond0'
