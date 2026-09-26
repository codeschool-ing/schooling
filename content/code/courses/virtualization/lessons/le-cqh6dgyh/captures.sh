#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the network description shown with
# cat, written into ana's home; the guests client, server and target, made by
# lab.sh vm on that network; the wait until target answers ssh after it is
# reverted; and forty seconds after asking the three to shut down.
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
quiet host 'printf "%s\n" "<network>" "  <name>labnet</name>" "  <bridge name=\"virbr2\"/>" "  <ip address=\"10.20.0.1\" netmask=\"255.255.255.0\">" "    <dhcp>" "      <range start=\"10.20.0.10\" end=\"10.20.0.50\"/>" "    </dhcp>" "  </ip>" "</network>" > /home/ana/labnet.xml; chown ana:ana /home/ana/labnet.xml'

block network
on host 'cat labnet.xml'
on host 'virsh net-define labnet.xml && virsh net-start labnet && virsh net-autostart labnet'

lab vm client labnet >/dev/null 2>&1
lab vm server labnet >/dev/null 2>&1
lab vm target labnet >/dev/null 2>&1

block machines
on host 'virsh list; virsh net-dhcp-leases labnet | grep -c ipv4'
on host 'grep -E " (client|server|target)$" /etc/hosts'
on host 'for m in client server target; do grep -E " (client|server|target)$" /etc/hosts | ssh $m "sudo tee -a /etc/hosts >/dev/null"; done'
on client 'getent hosts server target'

block server
on server 'sudo systemctl enable --now nginx 2>&1 | tail -1; echo "lab server: ok" | sudo tee /var/www/html/index.html'
on client 'curl -sS http://server/'

block break
on target 'sudo systemctl enable --now nginx 2>&1 | tail -1'
on target 'sudo sed -i "s/listen 80 default_server;/listen 80 default_server/" /etc/nginx/sites-enabled/default && sudo systemctl restart nginx'
on client 'curl -sS -m 5 http://target/'
on host 'virsh snapshot-create-as target broken --description "nginx config missing a semicolon" && virsh snapshot-create-as server clean && virsh snapshot-create-as client clean'

block diagnose
on target 'systemctl is-active nginx; sudo nginx -t'
on target 'sudo journalctl -u nginx --no-pager | grep -m1 -i emerg'

block fix
on target 'sudo sed -i "s/listen 80 default_server$/listen 80 default_server;/" /etc/nginx/sites-enabled/default && sudo nginx -t && sudo systemctl restart nginx && systemctl is-active nginx'
on client 'curl -sS -o /dev/null -w "%{http_code}\n" http://target/'

block again
on host 'virsh snapshot-revert target broken'
for i in $(seq 24); do ssh -o ConnectTimeout=5 target true 2>/dev/null && break; sleep 5; done
on client 'curl -sS -m 5 http://target/'

block cost
on host 'virsh list --all; free -h | head -2'
on host 'ps -o rss= -C qemu-system-x86_64 | awk "{ s += \$1 } END { print s, \"KiB for\", NR, \"guests\" }"'
on host 'for m in client server target; do virsh shutdown $m; done'
sleep 40
on host 'virsh list --all; virsh snapshot-list target'

lab down >/dev/null 2>&1
quiet host 'rm -f /home/ana/labnet.xml'
