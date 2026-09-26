#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset, with the office network (lab.sh
# office) standing in for the real one; labnet, lesson 14's network, defined
# and started; the guests client and server, made by lab.sh vm on it, with
# nginx started on server; a web server ana left running on host, python3 -m
# http.server 8000, serving a folder of notes; check.sh and labguard.nft
# written into ana's home and check.sh copied to client; and the VirtualBox
# machine lab1, registered with a shared clipboard, drag and drop and NAT.
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
quiet host 'printf "%s\n" "<network>" "  <name>labnet</name>" "  <bridge name=\"virbr2\"/>" "  <ip address=\"10.20.0.1\" netmask=\"255.255.255.0\">" "    <dhcp>" "      <range start=\"10.20.0.10\" end=\"10.20.0.50\"/>" "    </dhcp>" "  </ip>" "</network>" > /home/ana/labnet.xml; chown ana:ana /home/ana/labnet.xml'
virsh -q -c qemu:///system net-define labnet.xml >/dev/null && virsh -q -c qemu:///system net-start labnet >/dev/null
lab vm client labnet >/dev/null 2>&1
lab vm server labnet >/dev/null 2>&1
for m in client server; do grep -E " (client|server)$" /etc/hosts | ssh $m "sudo tee -a /etc/hosts >/dev/null"; done
quiet server 'systemctl enable --now nginx; echo "lab server: ok" > /var/www/html/index.html'
mkdir -p ~/notes && echo "renew the office printer's toner" > ~/notes/todo.txt
setsid python3 -m http.server 8000 --directory ~/notes >/dev/null 2>&1 < /dev/null &
notes_server=$!
cat > ~/check.sh <<'CHECK'
#!/usr/bin/env bash
# Run inside a lab guest, with the host's address on the lab network.
host=${1:?usage: check.sh HOST_ADDRESS}

check() {
  if "${@:2}" >/dev/null 2>&1; then echo "$1: OPEN"; else echo "$1: closed"; fi
}

check "a route out of the lab"  ip route get 10.0.0.50
check "the host's ssh"          nc -z -w 3 "$host" 22
check "the host's port 8000"    nc -z -w 3 "$host" 8000
check "a shared folder"         grep -qE " (9p|virtiofs) " /proc/mounts
check "a clipboard agent"       pgrep -x "spice-vdagent|VBoxClient"
CHECK
cat > ~/labguard.nft <<'GUARD'
table inet labguard {
  chain input {
    type filter hook input priority 0; policy accept;
    iifname "virbr2" ct state established,related accept
    iifname "virbr2" udp dport { 53, 67 } counter accept
    iifname "virbr2" tcp dport 53 counter accept
    iifname "virbr2" counter drop
  }
}
GUARD
scp -q ~/check.sh client:

block wall
on host 'ip route get 10.0.0.50'
on client 'ip route; ip route get 10.0.0.50'
on client 'curl -sS -m 5 http://server/'

block holes
on host 'ss -tln | grep -E ":(22|8000) "'
on client 'curl -sS -m 5 http://10.20.0.1:8000/todo.txt; nc -zv -w 3 10.20.0.1 22'

block before
on client 'bash check.sh 10.20.0.1'

block guard
on host 'cat labguard.nft'
on host 'sudo nft -f labguard.nft && sudo nft list tables'

block after
on client 'bash check.sh 10.20.0.1'
on client 'curl -sS -m 5 http://server/'
on client 'sudo networkctl renew enp1s0 && sleep 5 && ip -4 -br addr show enp1s0'
on host 'sudo nft list table inet labguard'

block keep
on host 'grep -n "flush ruleset" /etc/nftables.conf'

block doors
on host 'virsh dumpxml client | grep -E "<(interface|filesystem|graphics|channel) "'
quiet host 'ln -sf /usr/lib/virtualbox/VBoxManage /usr/local/bin/VBoxManage; runuser -u ana -- VBoxManage createvm --name lab1 --ostype Ubuntu_64 --register; runuser -u ana -- VBoxManage modifyvm lab1 --clipboard-mode bidirectional --drag-and-drop hosttoguest --nic1 nat'
on host 'VBoxManage modifyvm lab1 --clipboard-mode disabled --drag-and-drop disabled --nic1 intnet --intnet1 labnet && VBoxManage showvminfo lab1 --machinereadable | grep -E "^(clipboard|draganddrop|nic1|intnet1)="'
quiet host 'runuser -u ana -- VBoxManage unregistervm lab1 --delete; rm -rf "/home/ana/VirtualBox VMs" /usr/local/bin/VBoxManage'

quiet host 'nft delete table inet labguard'
kill "$notes_server"
lab down >/dev/null 2>&1
quiet host 'rm -rf /home/ana/labnet.xml /home/ana/notes /home/ana/check.sh /home/ana/labguard.nft'
