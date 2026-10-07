#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. This lesson adds an access switch to the office LAN: sw, with
# two ports, p1 and p2, and an uplink into the LAN. newpc is a company laptop
# on p1 and visitor is somebody's own machine on p2. root@sw is the switch's
# administrator; root@newpc and root@visitor are the administrators of the two
# machines, because the 802.1X client needs root to open the interface.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset and nac.sh (lab nac). That second step makes
# the switch and the two machines, issues nac.corp.example.com (the
# authenticator's certificate) and newpc.corp.example.com (the laptop's) from
# the lab's issuing CA, lets visitor sign a certificate of its own, writes
# wpa.conf on both machines and the hostapd configuration and port-control.sh
# on the switch, and loads ports.nft there. Each of those files is shown in the
# lesson. No rule set is loaded on fw in this lesson: the switch port is the
# only control being tested. In the real world the authenticator asks a RADIUS
# server; here hostapd's own EAP server stands in for it, which is the same
# EAP-TLS exchange without the second hop.
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

lab reset >/dev/null 2>&1
lab nac

block closed
root sw 'nft list table netdev ports'
on newpc 'ip -br address show eth0'
on newpc 'ping -c 2 -W 1 192.168.10.1'

block authenticator
root sw 'cat hostapd-p1.conf'
root sw 'cat port-control.sh'
root sw 'hostapd -B -f /var/log/lab/hostapd.log hostapd-p1.conf hostapd-p2.conf'
sleep 1
root sw 'hostapd_cli -p /root/hostapd-ctrl -i p1 -a /root/port-control.sh -B'
root sw 'hostapd_cli -p /root/hostapd-ctrl -i p2 -a /root/port-control.sh -B'
sleep 1

block success
root newpc 'openssl x509 -in client.crt -noout -subject -issuer -enddate'
root newpc 'wpa_supplicant -B -D wired -i eth0 -c wpa.conf -f /var/log/lab/wpa.log -P /root/wpa.pid'
sleep 4
root newpc 'grep -o "CTRL-EVENT-EAP-[A-Z-]*.*" /var/log/lab/wpa.log'
root sw 'nft list set netdev ports authorised'
on newpc 'ping -c 2 -W 1 192.168.10.1'

block refused
root visitor 'openssl x509 -in client.crt -noout -subject -issuer -enddate'
root visitor 'wpa_supplicant -B -D wired -i eth0 -c wpa.conf -f /var/log/lab/wpa.log -P /root/wpa.pid'
sleep 4
root visitor 'grep -o "CTRL-EVENT-EAP-[A-Z-]*.*" /var/log/lab/wpa.log'
root sw 'grep -E "^p2: |verification failed" /var/log/lab/hostapd.log'
on visitor 'ping -c 2 -W 1 192.168.10.1'

block borrowed
root visitor 'kill $(cat wpa.pid)'
root visitor 'ip link set eth0 down; ip link set eth0 address 52:54:00:a8:0a:1e; ip link set eth0 up'
on visitor 'ip -br link show eth0'
on visitor 'ping -c 2 -W 1 192.168.10.1'
on newpc 'ping -c 2 -W 1 192.168.10.1'

block identity
root sw 'hostapd_cli -p /root/hostapd-ctrl -i p1 sta 52:54:00:a8:0a:1e | grep -E "^flags|UserName|ReAuthPeriod|eap_type_sta"'
root sw 'cat /var/log/lab/ports.log'
root newpc 'wpa_cli -p /root/wpa-ctrl -i eth0 logoff'
sleep 2
root sw 'nft list set netdev ports authorised'
root sw 'cat /var/log/lab/ports.log'
on newpc 'ping -c 2 -W 1 192.168.10.1'
