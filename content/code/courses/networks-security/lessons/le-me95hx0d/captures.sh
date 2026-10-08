#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana   # this lesson runs sudo as ana
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds a company's
# network out of network namespaces on one Linux computer: a firewall, fw, with
# the internet, a DMZ, the staff LAN, a server segment and a management segment
# behind its five interfaces. A line that starts with ana@laptop ran on the
# machine called laptop; root@fw is the administrator on the firewall.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with fw routing and filtering nothing;
# a listener on laptop's port 9999 before the stateless-hole block, standing
# in for any service a workstation happens to run.
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

# THE SETUP SECTIONS run on the lab's own host, as ana, with nslab.sh in
# ~/nslab exactly as the lesson shows it (lab.sh has just extracted it). The
# prompt of the host is a bare $. A shell opened with "sh" or "root" is driven
# through script(1), so it has a terminal, and its control sequences are
# removed from what it printed.
lab down >/dev/null 2>&1
install -d -o ana -g ana /home/ana/nslab
install -o ana -g ana -m 644 /var/tmp/nslab/nslab.sh /home/ana/nslab/nslab.sh
host() { printf '$ %s\n' "$1"; runuser -u ana -- bash -c "cd ~/nslab && $1" 2>&1 || true; }
shell() {  # shell 'sh laptop' 'command' ...: an interactive shell on a machine
  local how=$1; shift
  printf '$ sudo bash nslab.sh %s\n' "$how"
  printf '%s\n' "$@" exit | runuser -u ana -- script -qec "cd ~/nslab && sudo bash nslab.sh $how" /dev/null \
    | sed -e 's/\x1b\[?2004[hl]//g; s/\x1b\]0;[^\x07]*\x07//g; s/\r//g' | sed -n '/^[a-z]*@[a-z]*:~[$#] /,$p'
}

block build
host 'sha256sum nslab.sh; wc -l nslab.sh'
host 'time sudo bash nslab.sh up'
host 'ip netns list | cut -d" " -f1 | sort | tr "\n" " "; echo'

block shell
shell 'sh laptop' 'hostname' 'probe db:5432 www:443' 'curl -s https://www.example.com/'
shell 'root fw' 'nft list ruleset | wc -l'

block files
host 'ls -x /lab'
host 'sudo ls -A /lab/laptop/home/ana'

block no-sudo
lab down >/dev/null 2>&1
host 'bash nslab.sh up; echo "exit $?"'

block crlf
runuser -u ana -- bash -c 'cd ~/nslab && sed "s/$/\r/" nslab.sh > windows.sh'
host 'sudo bash windows.sh up 2>&1 | cat -v | head -3; file windows.sh'
host 'sed -i "s/\r$//" windows.sh; cmp windows.sh nslab.sh && echo same'
runuser -u ana -- rm -f /home/ana/nslab/windows.sh

block twice
install -o ana -g ana -m 644 /var/tmp/nslab/inline.sh /home/ana/nslab/inline.sh
host 'sudo bash nslab.sh up; sudo bash inline.sh; sudo bash inline.sh; echo "exit $?"'
host 'sudo bash nslab.sh reset; sudo bash inline.sh; echo "exit $?"'
runuser -u ana -- rm -f /home/ana/nslab/inline.sh
lab down >/dev/null 2>&1

block missing
apt-get remove -y -qq aide >/dev/null 2>&1
host 'sudo bash nslab.sh up; echo "exit $?"'
apt-get install -y -qq aide >/dev/null 2>&1

lab reset

block open
on remote 'nc -w2 192.168.20.30 5432 </dev/null'
on remote 'curl -s -m2 http://192.168.20.10:8080/admin/'
root fw 'iptables -V'

block stateless
quiet fw 'cat > /root/stateless.nft <<"NFT"
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    iifname "eth2" oifname "eth3" tcp dport 8080 accept
  }
}
NFT'
root fw 'cat stateless.nft'
root fw 'nft -f stateless.nft'
on laptop 'curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"'

block stateless-return
quiet fw 'cat > /root/stateless.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    iifname "eth2" oifname "eth3" tcp dport 8080 accept
    iifname "eth3" oifname "eth2" tcp sport 8080 accept
  }
}
NFT'
root fw 'nft -f stateless.nft'
on laptop 'curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"'

block stateless-hole
quiet laptop 'setsid socat TCP-LISTEN:9999,bind=192.168.10.20,fork,reuseaddr SYSTEM:"echo laptop answered" </dev/null >/dev/null 2>&1 &'
sleep 0.5
on db 'nc -w2 192.168.10.20 9999 </dev/null; echo "exit $?"'
on db 'nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"'

block stateful
quiet fw 'cat > /root/stateful.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept
  }
}
NFT'
root fw 'cat stateful.nft'
root fw 'nft -f stateful.nft'
on laptop 'curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"'
on db 'nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"'

block conntrack
quiet laptop 'setsid bash -c "exec 3<>/dev/tcp/192.168.20.10/8080; sleep 3" </dev/null >/dev/null 2>&1 &'
sleep 0.5
root fw 'conntrack -L 2>/dev/null'
sleep 4

block counters
quiet fw 'nft flush ruleset'
quiet fw 'cat > /root/stateful.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related counter accept
    ct state invalid counter drop
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new counter accept
    counter comment "everything else, about to be dropped"
  }
}
NFT'
root fw 'nft -f stateful.nft'
on laptop 'for i in 1 2 3; do curl -s -m2 -o /dev/null http://192.168.20.10:8080/health; done'
on remote 'nc -w2 192.168.20.30 5432 </dev/null; echo "exit $?"'
root fw 'nft list chain ip filter forward'

block related
quiet fw 'cat > /root/related.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established counter accept
    ct state related counter accept
    ct state invalid counter drop
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new counter accept
    iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new counter accept
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 udp dport 53 ct state new counter accept
  }
}
NFT'
root fw 'nft -f related.nft'
on laptop 'dig +short @192.0.2.53 www.example.com'
root fw 'conntrack -L -p udp 2>/dev/null'
on laptop 'dig +tries=1 @192.168.20.10 www.example.com'
root fw 'nft list chain ip filter forward | head -6'

block cost
root fw 'sysctl net.netfilter.nf_conntrack_max net.netfilter.nf_conntrack_count'
root fw 'sysctl net.netfilter.nf_conntrack_tcp_timeout_established net.netfilter.nf_conntrack_udp_timeout net.netfilter.nf_conntrack_udp_timeout_stream net.netfilter.nf_conntrack_tcp_loose'
