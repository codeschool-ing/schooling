#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash ../../lab.sh build                      # once: the images
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by hostlab.sh from
# lesson 1. sw is the switch: its network namespace holds the bridge br0 and
# one port per machine, port-desk among them, so a filter on port-desk sees
# every frame desk sends before the bridge forwards it. ana@sw is ana on the
# switch, ana@desk on the workstation.
#
# What is STAGED rather than typed: the lab, `up desk web`, fresh. The five
# small files of the lesson (macfilter.nft, nac.nft, hostapd.conf and
# port-control.sh on sw, wpa.conf on desk) are written into ~/nac by this
# script from the heredocs below; the lesson shows each one whole through the
# `cat` transcripts that print them back. 52:54:00:a8:3c:63 stands for the
# reception printer, which the lab does not have.
# Every line after a prompt is what the command printed. Certificates are made
# afresh on every run, so their dates are the day of the run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
write() { lab exec "$1" ana "mkdir -p nac && cat > nac/$2"; }

lab up desk web >/dev/null 2>&1

write sw macfilter.nft <<'EOF'
table netdev macfilter {
	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether saddr { 52:54:00:a8:3c:14, 52:54:00:a8:3c:63 } counter accept
		counter
	}
}
EOF
write sw nac.nft <<'EOF'
table netdev nac {
	set authorised {
		type ether_addr
	}

	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether type 0x888e accept
		ether saddr @authorised accept
		counter
	}
}
EOF
write sw hostapd.conf <<'EOF'
interface=port-desk
driver=wired
ieee8021x=1
eap_server=1
eap_user_file=/home/ana/nac/eap_user
ca_cert=/home/ana/nac/ca.crt
server_cert=/home/ana/nac/sw.crt
private_key=/home/ana/nac/sw.key
ctrl_interface=/run/hostapd
logger_stdout=-1
logger_stdout_level=2
EOF
write sw port-control.sh <<'EOF'
#!/bin/bash
# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC
case $2 in
  AP-STA-CONNECTED)
    nft add element netdev nac authorised "{ $3 }"
    logger -t nac "$1 $3 authorised" ;;
  AP-STA-DISCONNECTED)
    nft delete element netdev nac authorised "{ $3 }"
    logger -t nac "$1 $3 closed" ;;
esac
EOF
write desk wpa.conf <<'EOF'
ctrl_interface=/run/wpa_supplicant
ap_scan=0
network={
    key_mgmt=IEEE8021X
    eap=TLS
    identity="desk.jatoba.example"
    ca_cert="/home/ana/nac/ca.crt"
    client_cert="/home/ana/nac/desk.crt"
    private_key="/home/ana/nac/desk.key"
    eapol_flags=0
}
EOF

block mac-file
on sw 'cat nac/macfilter.nft'

block mac-load
on sw 'sudo nft -f nac/macfilter.nft && echo loaded'
on desk 'ping -c1 -W1 web | tail -2'

block mac-change
on desk 'sudo ip link set eth0 address 52:54:00:a8:3c:99; ping -c1 -W1 web | tail -2'
on desk 'sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2'
on desk 'sudo ip link set eth0 address 52:54:00:a8:3c:14'

block mac-counters
on sw 'sudo nft list chain netdev macfilter desk_port'
on sw 'sudo nft delete table netdev macfilter && echo removed'

block ca
on sw 'cd nac && openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Jatoba NAC CA" -keyout ca.key -out ca.crt 2>/dev/null && openssl x509 -in ca.crt -noout -subject'
on sw 'cd nac && openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=sw.jatoba.example" -keyout sw.key -out sw.csr 2>/dev/null && openssl x509 -req -in sw.csr -CA ca.crt -CAkey ca.key -days 365 -extfile <(echo extendedKeyUsage=serverAuth) -out sw.crt'

block csr
on desk 'cd nac && openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=desk.jatoba.example" -keyout desk.key -out desk.csr 2>/dev/null && scp -q desk.csr sw:nac/ && ls'
on sw 'cd nac && openssl x509 -req -in desk.csr -CA ca.crt -CAkey ca.key -days 365 -extfile <(echo extendedKeyUsage=clientAuth) -out desk.crt'
on desk 'cd nac && scp -q sw:nac/desk.crt sw:nac/ca.crt . && openssl x509 -in desk.crt -noout -subject -issuer -ext extendedKeyUsage'

block authenticator-files
on sw 'cat nac/hostapd.conf; echo "* TLS" > nac/eap_user'
on sw 'cat nac/nac.nft nac/port-control.sh'

block authenticator
on sw 'sudo nft -f nac/nac.nft && chmod +x nac/port-control.sh && sudo hostapd -B -P /run/hostapd.pid nac/hostapd.conf'
on sw 'sudo hostapd_cli -B -a /home/ana/nac/port-control.sh && sudo hostapd_cli status | grep ^state'
on desk 'ping -c1 -W1 web | tail -2'

block supplicant
on desk 'cat nac/wpa.conf'
on desk 'sudo wpa_supplicant -B -D wired -i eth0 -c nac/wpa.conf; sleep 3; sudo wpa_cli status | grep -E "PAE|PortStatus|EAP state|selectedMethod"'
on desk 'ping -c1 -W1 web | tail -2'

block opened
on sw 'sudo nft list set netdev nac authorised'
on sw 'sudo journalctl -t nac --no-pager -o cat'

block bound
on desk 'sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2'
on desk 'sudo ip link set eth0 address 52:54:00:a8:3c:14; ping -c1 -W1 web | tail -2'

block logoff
on desk 'sudo wpa_cli logoff >/dev/null; sleep 2; ping -c1 -W1 web | tail -2'
on sw 'sudo journalctl -t nac --no-pager -o cat'

