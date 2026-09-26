#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guests srv1 and pc1, made by lab.sh
# vm, with srv1's address in pc1's /etc/hosts; and on srv1 THE SALES SYSTEM, a
# stand-in for another team's application: a user sales, a three-line Python
# program /opt/sales/api.py that reads /etc/sales/api.conf and then serves on
# 127.0.0.1:9000, the service sales-api that runs it as sales, and nginx
# passing /sales/ to it. THE FAULT: api.conf belongs to root with mode 600,
# so sales cannot read it and the service fails on every start.
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
lab vm srv1 >/dev/null 2>&1
lab vm pc1 >/dev/null 2>&1
quiet host 'for m in pc1; do grep -E " srv1$" /etc/hosts | runuser -u ana -- ssh $m "sudo tee -a /etc/hosts >/dev/null"; done'
quiet srv1 'useradd -r -s /usr/sbin/nologin sales; mkdir -p /opt/sales /etc/sales; printf "%s\n" "import http.server" "cfg = open(\"/etc/sales/api.conf\").read()" "http.server.test(HandlerClass=http.server.SimpleHTTPRequestHandler, port=9000, bind=\"127.0.0.1\")" > /opt/sales/api.py; echo "db=sales" > /etc/sales/api.conf; chmod 600 /etc/sales/api.conf; printf "%s\n" "[Unit]" "Description=Sales API" "StartLimitIntervalSec=60" "StartLimitBurst=3" "[Service]" "User=sales" "ExecStart=/usr/bin/python3 /opt/sales/api.py" "Restart=on-failure" "RestartSec=1" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/sales-api.service; printf "%s\n" "server {" "  listen 80 default_server;" "  location /sales/ { proxy_pass http://127.0.0.1:9000/; }" "}" > /etc/nginx/sites-enabled/default; systemctl daemon-reload; systemctl enable --now nginx; systemctl start sales-api; sleep 8'

block symptom
on pc1 'date "+%H:%M"; curl -sS -o /dev/null -w "%{http_code}\n" http://srv1/sales/'

block evidence
on srv1 'sudo tail -n 1 /var/log/nginx/error.log'
on srv1 'ss -tln | grep -c ":9000 "; systemctl is-active sales-api'
on srv1 'sudo journalctl -u sales-api --no-pager -o cat | grep -m1 -E "PermissionError"'
on srv1 'ls -l /etc/sales/api.conf; systemctl show -p User sales-api'

block bundle
on srv1 'mkdir -p ~/esc && sudo tail -n 20 /var/log/nginx/error.log > ~/esc/nginx-error.log && sudo journalctl -u sales-api --no-pager > ~/esc/sales-api.journal && systemctl status sales-api --no-pager > ~/esc/sales-api.status; tar czf sales-502.tar.gz -C ~ esc && tar tzf sales-502.tar.gz && ls -l sales-502.tar.gz'

lab down >/dev/null 2>&1
