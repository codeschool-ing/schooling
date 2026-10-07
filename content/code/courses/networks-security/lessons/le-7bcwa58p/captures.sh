#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of networks-security, as a script that produces them.
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
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw before each block that says so; the expected results of the
# regression test written beside the test on the lab's host; the test
# script itself, shown whole in the lesson, which runs on the lab's own host
# (the prompt that is a bare $) because only it can start a connection from
# every zone; the lab's probe command.
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

lab reset
quiet fw 'nft -f baseline.nft'

block shadow
root fw "nft add rule ip filter forward ip saddr 192.168.10.20 counter drop comment '\"laptop quarantined, ticket 5120\"'"
on laptop 'probe app:8080 www:443'
root fw 'nft -a list chain ip filter forward | grep -E "staff use|quarantined" | sed "s/^\t*//"'

block shadow-fix
root fw 'nft -a list chain ip filter forward | sed -n "3,4p;/quarantined/p" | sed "s/^\t*//"'
root fw 'nft delete rule ip filter forward handle 20'
root fw "nft insert rule ip filter forward position 4 ip saddr 192.168.10.20 counter drop comment '\"laptop quarantined, ticket 5120\"'"
root fw 'nft list chain ip filter forward | sed -n "3,6p" | sed "s/^\t*//"'
on laptop 'probe app:8080 www:443'
root fw 'nft list chain ip filter forward | grep quarantined | sed "s/^\t*//"'

block mask
quiet fw 'nft -f baseline.nft'
root fw "nft add rule ip filter forward ip saddr 192.168.99.0/16 oifname eth3 tcp dport 22 ct state new accept comment '\"admins reach the servers over SSH\"'"
root fw 'nft list chain ip filter forward | grep "admins reach" | sed "s/^\t*//"'
on laptop 'probe app:22 db:22'

block direction
quiet fw 'nft -f baseline.nft'
root fw "nft add rule ip filter forward iifname eth0 oifname eth1 ip saddr 192.0.2.53 tcp dport 443 counter accept comment '\"dns fetches its updates\"'"
on dns 'probe remote:443'
root fw 'nft list chain ip filter forward | grep "its updates" | sed "s/^\t*//"'

block unreachable
quiet fw 'nft -f baseline.nft'
root fw "nft add rule ip filter forward counter drop comment '\"drop everything else, and count it\"'"
root fw "nft add rule ip filter forward iifname eth2 oifname eth3 ip daddr 192.168.20.30 tcp dport 5432 counter accept comment '\"finance reporting reads the database\"'"
on laptop 'probe db:5432'
root fw 'nft list chain ip filter forward | tail -4 | head -2 | sed "s/^\t*//"'

block regression
quiet fw 'nft -f baseline.nft; nft add rule ip filter forward ip saddr 192.168.99.0/16 oifname \"eth3\" tcp dport 22 ct state new accept comment \"admins reach the servers over SSH\"'
# The regression test runs on the lab's own host, as ana, the one machine that
# can start a connection from every zone: its prompt is a bare $. The script is
# extracted from the lesson, byte for byte as the copy button gives it, and it
# calls ~/nslab/nslab.sh with sudo, so ana needs the extracted lab there and a
# sudoers entry (see the header).
m=/home/ana/matrix
install -d -o ana -g ana /home/ana/nslab "$m"
install -o ana -g ana -m 644 /var/tmp/nslab/nslab.sh /home/ana/nslab/nslab.sh
cat > "$m/matrix.expected" <<'T'
remote  www:443      open
remote  app:8080     blocked
remote  db:5432      blocked
laptop  app:8080     open
laptop  app:22       blocked
laptop  db:5432      blocked
admin   app:22       open
admin   app:8080     blocked
www     app:8080     open
www     db:5432      blocked
T
python3 - "$(dirname "$(readlink -f "$0")")/a-regression-test.md" > "$m/matrix-test.sh" <<'PY'
import json, re, sys
for b in re.findall(r"^```schooling-example\n(.*?)\n```$", open(sys.argv[1]).read(), re.S | re.M):
    ex = json.loads(b)
    if ex.get("file") == "matrix-test.sh":
        print("\n".join(p["code"] for p in ex["parts"]))
PY
chown ana:ana "$m"/*
host() { printf '$ %s\n' "$*"; runuser -u ana -- bash -c "cd ~/matrix && $*" 2>&1; }
host 'cat matrix.expected'
host 'bash matrix-test.sh; echo "exit $?"'
quiet fw 'nft -f baseline.nft'
host 'bash matrix-test.sh; echo "exit $?"'
