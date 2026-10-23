#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of defense-hardening, as a script that produces them.
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
# the hostlab.sh lesson 1 shows: web, desk and admin are started fresh. A line
# that starts with ana@web ran on the machine called web, as ana.
#
# What is STAGED rather than typed:
# - sensor.py and detect.py are written onto web from this lesson's own
#   Markdown (section "A sensor in forty lines" and "Rules over the telemetry"),
#   byte for byte as the copy button hands them over: the student pastes them.
# - isolate.nft is written into ana's home on web from section "Response" the
#   same way.
# - the "incident" is a harmless command the lesson tells the student to run:
#   sudo -u portal starts a shell as the portal's account, which tries a
#   download from 192.168.60.99 (an address in the lab where nothing answers,
#   so curl waits its two seconds and fails), copies /bin/sleep to
#   /tmp/update and leaves it running. sudo stands in for whatever made the
#   portal run a command; nothing is attacked.
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

lab up web desk admin >/dev/null 2>&1

block telemetry
on web 'ps -eo user,pid,ppid,args --forest | grep -E "nginx|portal|sshd" | grep -v grep'

block logins
on admin 'ssh web true'
on web 'sudo journalctl -u ssh --no-pager -o short-iso | grep Accepted'

block audit
on web 'sudo auditctl -l; echo "exit $?"'

put web root /usr/local/sbin/sensor.py sensor.py
put web ana /home/ana/detect.py detect.py
put web ana /home/ana/isolate.nft isolate.nft

block sensor-start
on web 'sha256sum /usr/local/sbin/sensor.py'
on web 'sudo systemd-run --unit sensor /usr/bin/python3 /usr/local/sbin/sensor.py'
on web 'sleep 1; grep "\"sleep 1\"" /var/log/sensor.jsonl | jq .'

block gap
on web 'for i in $(seq 20); do /bin/true; done; sleep 1; grep -c "\"/usr/bin/true\"" /var/log/sensor.jsonl'
on web 'sleep 0.5; sleep 1; grep -c "\"sleep 0.5\"" /var/log/sensor.jsonl'

block incident
on web "sudo -u portal bash -c 'curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &'"
sleep 1

block detect
on web 'python3 detect.py /var/log/sensor.jsonl'

block hunt
on web "jq -r 'select(.user == \"portal\") | [.time, .cmd] | @tsv' /var/log/sensor.jsonl"

block evidence
on web 'pgrep -a -u portal'
on web 'pid=$(pgrep -f "^/tmp/update"); sudo sha256sum /proc/$pid/exe /usr/bin/sleep'
on web 'pid=$(pgrep -f "^/tmp/update"); sudo cat /proc/$pid/environ | tr "\0" "\n" | grep -E "^(USER|SUDO_USER|PWD)="'

block kill
on web 'sudo pkill -u portal -f "^/tmp/update"; sleep 1; pgrep -a -u portal'

block isolate
on web 'sudo nft -f isolate.nft && sudo nft list tables'
on desk 'ping -c1 -W1 web | tail -2; curl -s -m3 http://web/; echo "exit $?"'
on admin 'ssh web "hostname; uptime -p"'

block release
on web 'sudo nft delete table inet isolate; sudo nft list tables'
on desk 'curl -s -m3 http://web/'
