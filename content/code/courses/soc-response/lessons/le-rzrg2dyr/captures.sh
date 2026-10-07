#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, with soclab.sh (lab.sh beside
# course.json) in root's home folder. Commands at root@soc run as root.
#
# STAGED, NOT TYPED: the four files beside this script are the ones the lesson
# prints and tells the student to write. They are copied into place before the
# commands that use them: remote.conf to /etc/rsyslog.d/10-remote.conf,
# gw-rsyslog.conf to /etc/soclab/gw-rsyslog.conf, logrotate-remote to
# /etc/logrotate.d/remote, chain.sh to root's home folder. The recording machine
# had no systemd, so where the lesson says `systemctl restart rsyslog` the
# script stops rsyslog and starts it again by hand, as soc and in São Paulo
# time. The lab is torn down and built fresh at the start.
#
# Recorded on Ubuntu 24.04 (rsyslog 8.2312.0, logrotate 3.21.0), TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }
restart_rsyslog() {
  pkill -x rsyslogd; while pgrep -x rsyslogd >/dev/null; do sleep 1; done
  rm -f /run/rsyslogd.pid /run/rsyslogd-gw.pid
  env -i $ENV unshare --uts sh -c 'hostname soc; rsyslogd'
  sleep 1
}

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
quiet 'bash soclab.sh down; rm -rf /var/log/soclab /var/log/remote /var/spool/rsyslog-gw /root/gw-day1.log* /root/chain.sh'
pkill -x rsyslogd
quiet 'bash soclab.sh up'
install -m 644 "$HERE/remote.conf" /etc/rsyslog.d/10-remote.conf
mkdir -p /etc/soclab; install -m 644 "$HERE/gw-rsyslog.conf" /etc/soclab/gw-rsyslog.conf
install -m 644 "$HERE/logrotate-remote" /etc/logrotate.d/remote
install -m 755 "$HERE/chain.sh" /root/chain.sh
sleep 2

block receiver
root 'mkdir -p /var/log/remote && chown syslog:adm /var/log/remote && chmod 750 /var/log/remote'
restart_rsyslog
root 'ss -ltn src 192.168.99.10'

block sender
root 'mkdir -p /var/spool/rsyslog-gw'
root 'ip netns exec gw rsyslogd -f /etc/soclab/gw-rsyslog.conf -i /run/rsyslogd-gw.pid'
sleep 1
root 'ip netns exec outside ssh -o BatchMode=yes -o StrictHostKeyChecking=no admin@198.51.100.22 true'
sleep 3
root 'cat /var/log/remote/gw.log'

block seal
root 'cp /var/log/remote/gw.log gw-day1.log'
root 'sha256sum gw-day1.log | tee gw-day1.log.sha256'
root 'sha256sum -c gw-day1.log.sha256'
root "sed -i 's/203.0.113.66/198.51.100.99/' gw-day1.log"
root 'sha256sum -c gw-day1.log.sha256'

block chain
quiet 'cp /var/log/remote/gw.log gw-day1.log'
root 'bash chain.sh gw-day1.log'
root "sed -i '2d' gw-day1.log"
root 'bash chain.sh gw-day1.log'

block rotate
root 'ls -l /var/log/remote'
root 'logrotate -f /etc/logrotate.d/remote'
root 'ls -l /var/log/remote'
