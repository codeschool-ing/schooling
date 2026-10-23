#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of defense-hardening, as a script that produces them.
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
# the hostlab.sh lesson 1 shows: web and desk are started fresh. A line that
# starts with ana@web ran on the machine called web, as ana.
#
# What is STAGED rather than typed:
# - portal-out.nft, 10-network.conf and web-egress.nft are written into ana's
#   home on web from this lesson's own Markdown, byte for byte as the copy
#   button hands them over: the student pastes them.
# - the trace block starts `nft monitor trace` in the background for three
#   seconds and sends one packet while it listens; the lesson tells the
#   student to run the monitor in a second shell.
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

lab up web desk >/dev/null 2>&1
for f in portal-out.nft 10-network.conf web-egress.nft; do put web ana "/home/ana/$f" "$f"; done

block reach
on desk 'nc -zv -w2 web 22 2>&1; nc -zv -w2 web 80 2>&1'
on web 'sudo -u portal nc -zv -w2 desk 22 2>&1'

block portal-out
on web 'sudo nft -f portal-out.nft'
on web 'sudo -u portal nc -zv -w2 desk 22 2>&1; echo "exit $?"'
on web 'nc -zv -w2 desk 22 2>&1'
on desk 'curl -s http://web/'
on web 'sudo nft list chain inet portal_out output | grep counter'

block unit
on web 'sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 10-network.conf /etc/systemd/system/portal.service.d/'
on web 'sudo systemctl daemon-reload && sudo systemctl restart portal && systemctl show portal -p IPAddressDeny -p IPAddressAllow'
on desk 'curl -s http://web/'

block unit-test
on web 'sudo systemd-run -q --wait --pipe -p IPAddressDeny=any -p IPAddressAllow=localhost nc -zv -w2 desk 22 2>&1'

block cgroup
on web 'sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject'
on web 'sudo systemd-run -q --unit probe sh -c "sleep 3; nc -zv -w2 desk 22"'
on web 'sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject'
on web 'sleep 4; sudo journalctl -u probe -o cat --no-pager | grep nc:'
on web 'sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/portal.service" counter'
on desk 'for i in 1 2 3; do curl -s -o /dev/null http://web/; done'
on web 'sudo nft list chain inet portal_out output | grep cgroupv2'

block egress
on web 'sudo nft -f web-egress.nft'
on web 'nc -zv -w2 desk 22 2>&1; echo "exit $?"'
on desk 'curl -s http://web/; ssh web hostname'
on web 'sudo nft list chain inet web_egress output | grep counter'

block trace
on web 'sudo nft insert rule inet web_egress output meta nftrace set 1'
lab exec web root 'timeout 3 nft monitor trace > /tmp/trace.txt 2>&1 &' >/dev/null 2>&1
sleep 1
on web 'nc -z -w1 desk 22; echo "exit $?"'
sleep 3
on web 'sudo cat /tmp/trace.txt | head -8 | cut -c1-150'
