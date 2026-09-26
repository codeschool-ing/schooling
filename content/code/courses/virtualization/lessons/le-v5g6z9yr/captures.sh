#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the office network (lab.sh office),
# which stands in for the network host's own card would be plugged into; the
# two network descriptions shown with cat, written into ana's home; the guests
# vmn, vmb and vmi, made by lab.sh vm on the networks default, lan and
# isolated; and nginx started on vmn and vmb, so the printer has something to
# ask for.
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
lab office
quiet host 'printf "%s\n" "<network>" "  <name>lan</name>" "  <forward mode=\"bridge\"/>" "  <bridge name=\"lan0\"/>" "</network>" > /home/ana/lan.xml; printf "%s\n" "<network>" "  <name>isolated</name>" "  <bridge name=\"virbr1\"/>" "  <ip address=\"10.10.10.1\" netmask=\"255.255.255.0\">" "    <dhcp>" "      <range start=\"10.10.10.10\" end=\"10.10.10.50\"/>" "    </dhcp>" "  </ip>" "</network>" > /home/ana/isolated.xml; chown ana:ana /home/ana/lan.xml /home/ana/isolated.xml'

block default-net
on host 'virsh net-list --all'
on host 'virsh net-dumpxml default | grep -E "<(forward|bridge|ip|range) "'
on host 'sudo iptables -t nat -S | grep 192.168.122'

block office
on host 'ip -br addr show lan0'
on host 'curl -sS http://10.0.0.50/'

block define
on host 'cat lan.xml'
on host 'virsh net-define lan.xml && virsh net-start lan'
on host 'cat isolated.xml'
on host 'virsh net-define isolated.xml && virsh net-start isolated'
on host 'virsh net-list'

lab vm vmn >/dev/null 2>&1
lab vm vmb lan >/dev/null 2>&1
lab vm vmi isolated >/dev/null 2>&1
quiet vmn 'systemctl start nginx'
quiet vmb 'systemctl start nginx'

block nat
on vmn 'ip -br addr show enp1s0; ip route | head -1'
on vmn 'curl -sS http://10.0.0.50/'
on host 'tail -1 /var/log/office-http.log'
on host 'sudo ip netns exec printer curl -sS -m 5 http://$(getent hosts vmn | cut -d" " -f1)/'

block bridged
on vmb 'ip -br addr show enp1s0; ip route | head -1'
on vmb 'curl -sS http://10.0.0.50/'
on host 'tail -1 /var/log/office-http.log'
on host 'sudo ip netns exec printer curl -sS -m 5 -o /dev/null -w "%{http_code}\n" http://$(getent hosts vmb | cut -d" " -f1)/'
on host 'sudo cat /run/office-dhcp.leases'

block isolated
on vmi 'ip -br addr show enp1s0; ip route'
on vmi 'curl -sS -m 5 http://10.0.0.50/'
on vmi 'nc -zv -w 3 10.10.10.1 53'

lab down >/dev/null 2>&1
quiet host 'rm -f /home/ana/lan.xml /home/ana/isolated.xml'
