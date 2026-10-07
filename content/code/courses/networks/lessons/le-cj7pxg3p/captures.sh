#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo useradd -m -s /bin/bash -G sudo ubuntu  # the same, with sudo needing no
#                                                # password, as Multipass gives it
#   (lab.sh, beside course.json, builds the lab from the four files lesson 1
#   shows, so the repository has to be readable by ana)
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# THE VIRTUAL MACHINE of sections 03 to 09 is played by a UTS namespace whose
# hostname is netlab, entered as the account ubuntu, with netlab named in
# /etc/hosts as the machine's own name is on a real one. Its ~/netlab holds the
# four files lab.sh copied out of this lesson, compared byte for byte before
# anything runs, so what section 08 runs is what sections 04 to 07 print.
#
# What is STAGED rather than typed, and not shown in the lesson:
# for the failures of section 09, the lab torn down first, swaks removed and
# put back, and dns.sh cut after its first hundred lines and then restored;
# the lab itself, built by lab.sh reset; the ARP caches of laptop and server
# emptied before the neighbour block, so the first ping has to ask; and the
# default route put back on laptop after its link is brought down and up,
# because taking a link down removes the routes that used it.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-$(dirname "$(readlink -f "$0")")/../../lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {
  printf 'ana@%s:~$ %s\n' "$1" "$2" > /tmp/bg.out
  lab exec "$1" ana "$2" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 1.5
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

# A shell on the virtual machine, in a real terminal, as ubuntu, with the lines
# on stdin typed into it one at a time. "@sleep N" is not typed: it waits for a
# command that takes longer than a line's pause, as a person would.
cat > /tmp/vm-shell.sh <<'SH'
printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.vm
INPUTRC=/tmp/inputrc.vm script -qec "env PS1='\u@\h:\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null
SH
chmod 644 /tmp/vm-shell.sh
vm() {
  local cmds; cmds=$(cat)
  { sleep 1
    while IFS= read -r l; do
      case $l in @sleep\ *) sleep "${l#@sleep }"; continue ;; esac
      printf '%s\n' "$l"; sleep "${PAUSE:-2}"
    done <<< "$cmds"
    printf 'exit\n'; sleep 0.5; } |
    sudo unshare --uts sh -c 'hostname netlab; cd /home/ubuntu; exec runuser -u ubuntu -- env -i HOME=/home/ubuntu USER=ubuntu LOGNAME=ubuntu PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TERM=xterm LANG=C.UTF-8 COLUMNS=100 bash /tmp/vm-shell.sh' |
    tr -d '\r' | sed -E 's/\x1b\]0;[^\x07]*\x07//g; s/\x1b\[\?2004[hl]//g' | sed '$d' | sed '$d'
}

lab down
grep -qw netlab /etc/hosts || echo '127.0.1.1 netlab' | sudo tee -a /etc/hosts >/dev/null
sudo rm -rf /home/ubuntu/netlab
sudo install -d -o ubuntu -g ubuntu /home/ubuntu/netlab
for f in netlab dns.sh web.sh services.sh; do
  sudo install -m 644 -o ubuntu -g ubuntu /var/tmp/netlab/$f /home/ubuntu/netlab/$f
  sudo cmp /var/tmp/netlab/$f /home/ubuntu/netlab/$f || exit 1
done

block vm-ipv6
vm <<'IN'
ls /proc/sys/net/ipv6
IN

block vm-files
vm <<'IN'
wc -l ~/netlab/*
sha256sum ~/netlab/*
IN

block vm-up
vm <<'IN'
sudo bash ~/netlab/netlab up
@sleep 20
sudo bash ~/netlab/netlab shell laptop
@sleep 1
hostname
ip -br addr
curl -sI https://www.example.com/ | head -1
exit
sudo bash ~/netlab/netlab exec router root 'ip route'
IN

block fail-sudo
vm <<'IN'
bash ~/netlab/netlab up
IN

block fail-not-up
lab down
vm <<'IN'
sudo bash ~/netlab/netlab shell laptop
IN

block fail-package
sudo apt-get remove -y -q swaks >/dev/null 2>&1
vm <<'IN'
sudo bash ~/netlab/netlab up
IN
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q swaks >/dev/null 2>&1

block fail-cut
sudo cp /home/ubuntu/netlab/dns.sh /tmp/dns.sh.whole
sudo sh -c 'head -n 100 /tmp/dns.sh.whole > /home/ubuntu/netlab/dns.sh'
vm <<'IN'
wc -l ~/netlab/dns.sh
sudo bash ~/netlab/netlab up
IN
sudo cp /tmp/dns.sh.whole /home/ubuntu/netlab/dns.sh
lab down

lab reset

block link
on laptop 'ip link show eth0'
on laptop 'ip -br link'

block addr
on laptop 'ip -br addr'

block neigh
quiet laptop 'ip neigh flush all'
quiet server 'ip neigh flush all'
on laptop 'ip neigh'
bgon server 'sudo tcpdump -n -e -i eth0 -c 4 arp or icmp'
on laptop 'ping -c 1 192.168.10.10'
on laptop 'ip neigh'

block arp-wire
fgon

block route
on laptop 'ip route'
on laptop 'ip route get 192.0.2.80'
on laptop 'ping -c 3 192.0.2.80'

block trace
on laptop 'traceroute -n 192.0.2.80'

block ports
on www 'ss -tln'
on laptop 'nc -zv 192.0.2.80 443'
on laptop 'nc -zv 192.0.2.80 8080'

block curl
on laptop "curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E 'IPv4:|Trying|Connected|SSL connection|^> GET|^< HTTP'"

block frame
bgon laptop 'sudo tcpdump -n -e -XX -c 1 "tcp dst port 80 and tcp[tcpflags] & tcp-push != 0"'
lab exec laptop ana 'curl -s -o /dev/null http://www.example.com/' >/dev/null 2>&1
fgon

block fail-link
on laptop 'sudo ip link set eth0 down'
on laptop 'ping -c 2 192.0.2.80'
on laptop 'ip -br link show eth0'
quiet laptop 'ip link set eth0 up && ip route add default via 192.168.10.1'

block fail-arp
on laptop 'ping -c 2 192.168.10.99'

block fail-port
on laptop 'curl -sS http://www.example.com:8080/'

block fail-name
on laptop 'curl -sS https://ww.example.com/'

block fail-http
on laptop 'curl -sI https://www.example.com/prices'

lab down
