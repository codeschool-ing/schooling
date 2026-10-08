#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares: Ubuntu 24.04 with the course's
# packages and a user ana. Commands at root@soc run as root, at ana@soc as ana.
#
# STAGED, NOT TYPED: the recording machine had no systemd running, so rsyslog,
# which an Ubuntu 24.04 machine starts at boot, is started here by hand under
# the name soc and the time zone America/Sao_Paulo, after auth.log and syslog
# are emptied. For the same reason journald was not running, and the journalctl
# commands the lesson shows were NOT run here: the lesson says so where it
# prints them, and prints no output for them.
#
# Recorded on Ubuntu 24.04 (rsyslog 8.2312.0), TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
ana()  { printf 'ana@soc:~$ %s\n' "$*"; runuser -u ana -- env -i ${ENV/HOME=\/root/HOME=/home/ana} bash -c "cd; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

pkill -x rsyslogd
while pgrep -x rsyslogd >/dev/null; do sleep 1; done
rm -f /run/rsyslogd.pid
: > /var/log/auth.log; : > /var/log/syslog; : > /var/log/kern.log
env -i $ENV unshare --uts sh -c 'hostname soc; rsyslogd'
sleep 1

block files
root 'ls -l /var/log/auth.log /var/log/syslog /var/log/kern.log'
root "grep -v '^#' /etc/rsyslog.d/50-default.conf | grep ."

block su
root 'su - ana -c true'
root 'grep pam_unix /var/log/auth.log'

block logger
ana "logger -t backup 'nightly copy finished: 412 files'"
ana 'tail -n 1 /var/log/syslog'
root 'tail -n 1 /var/log/syslog'

block dates
root 'date'
root 'date -u'
root "date -d '2026-09-17T02:33:07-03:00' -u"
root "date -d 'Sep 17 02:33:07'"
