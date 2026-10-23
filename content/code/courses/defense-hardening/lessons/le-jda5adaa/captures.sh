#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of defense-hardening, as a script that produces them.
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
# lesson 1. ana@web is ana on the portal, ana@desk on a workstation, ana@admin
# on the administrators' machine.
#
# What is STAGED rather than typed: the lab, `up web desk admin`, fresh, so web
# still runs every service lesson 1 removed. nftables.conf is written into
# ana's home on web by this script from the heredoc below; the lesson shows it
# whole through the `cat` transcript that prints it back.
# There is no USB bus and no kernel module inside a container, so the
# removable-media part has transcripts only of what fails, and says so.
# Every line after a prompt is what the command printed.
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

lab up web desk admin >/dev/null 2>&1
lab exec web ana 'cat > nftables.conf' <<'EOF'
#!/usr/sbin/nft -f
# /etc/nftables.conf on web: the portal accepts what its job needs, and nothing else.
flush ruleset

table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		icmp type echo-request accept
		tcp dport 80 accept
		ip saddr { 192.168.60.30, 192.168.60.40 } tcp dport 22 accept
		counter
	}
}
EOF

block before
on desk 'for p in 21 22 23 80 111; do nc -zv -w2 web $p; done'

block listening
on web "sudo ss -Htln | awk '{print \$4}'"

block ruleset
on web 'cat nftables.conf'

block load
on web 'sudo nft -c -f nftables.conf && echo "syntax ok"'
on web 'sudo nft -f nftables.conf && echo loaded'

block after
on desk 'for p in 21 22 80; do nc -zv -w2 web $p; done'
on admin 'nc -zv -w2 web 22; ssh web hostname'
on web "sudo ss -Htln | awk '{print \$4}' | wc -l"

block counters
on web 'sudo nft list chain inet host input'

block drop-time
on desk 'time nc -zv -w3 web 21'

block reject
on web 'sed "s/^\t\tcounter$/\t\tcounter reject/" nftables.conf > reject.conf && grep reject reject.conf && sudo nft -f reject.conf'
on desk 'time nc -zv -w3 web 21'
on desk 'sudo nmap -Pn -p 21,22,23,80,111 web | grep tcp'

block persist
on web 'sudo cp nftables.conf /etc/nftables.conf && sudo systemctl enable --now nftables 2>&1 | sed "s/ → .*//"'
on web 'systemctl is-active nftables; sudo nft list ruleset | grep -c accept'
on web 'sudo systemctl restart nftables && sudo nft list ruleset | grep -E "policy|reject"'
on admin 'ssh web hostname'

block outside
on desk 'sudo nmap -Pn -p 21,22,23,80,111 web | grep tcp'

block usb
on web 'ls /sys/bus/usb'
on web 'sudo usbguard generate-policy; echo "exit $?"'
on web 'command -v modprobe || echo "no modprobe here"'
