#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything here runs as ana, in a folder called week in her home folder, on
# the machine lesson 1 prepares. No lab machine is involved: the week of logs
# is written by week.py.
#
# STAGED, NOT TYPED: week.py, load.py, failures.yml, rules-v1.yml, rules-v2.yml
# and alerts.sh, all beside this script, are the files the lesson prints in full
# and tells the student to write; they are copied into ~/week first. The one
# command that installs sigma-cli reached PyPI through the recording machine's
# HTTPS proxy, so it runs with that proxy's variables and its CA bundle, copied
# where ana may read it and named by CA= when the script is run; every other
# command runs with a clean environment. Old copies of ~/week and ~/sigma are removed first.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1, sigma-cli 3.1.0 and
# pySigma-backend-sqlite 2.0.0, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
# the proxy's CA bundle, copied where ana may read it (CA=..., or it is skipped)
CA=${CA:-}
NET="HTTPS_PROXY=${HTTPS_PROXY:-} https_proxy=${https_proxy:-} NO_PROXY=${NO_PROXY:-}${CA:+ PIP_CERT=$CA REQUESTS_CA_BUNDLE=$CA SSL_CERT_FILE=$CA}"
ana()     { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
ana_net() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV $NET bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

runuser -u ana -- bash -c 'cd; rm -rf -- week sigma; mkdir week'
for f in week.py load.py failures.yml rules-v1.yml rules-v2.yml alerts.sh; do
  install -o ana -g ana -m 644 "$HERE/$f" /home/ana/week/$f
done

block week
ana 'python3 week.py'
ana 'wc -l auth.log fw.log flows.csv'
ana 'head -n 2 auth.log; head -n 2 fw.log; head -n 3 flows.csv'

block load
ana 'python3 load.py'
ana "sqlite3 -header -column siem.db 'SELECT product, action, count(*) AS n FROM logs GROUP BY 1, 2'"

block row
ana "sqlite3 -line siem.db \"SELECT * FROM logs WHERE user = 'hr' LIMIT 1\""

block utc
ana "sqlite3 siem.db \"SELECT timestamp, raw FROM logs WHERE product = 'firewall' LIMIT 1\""

block install
ana_net 'python3 -m venv ~/sigma && ~/sigma/bin/pip install -q sigma-cli==3.1.0 pySigma-backend-sqlite==2.0.0'
ana '~/sigma/bin/sigma list targets'

block simple
ana '~/sigma/bin/sigma convert -t sqlite failures.yml'

block v1
ana '~/sigma/bin/sigma convert -t sqlite rules-v1.yml -o v1.sql'
ana 'wc -c v1.sql'
ana 'bash alerts.sh v1.sql'

block v2
ana '~/sigma/bin/sigma convert -t sqlite rules-v2.yml -o v2.sql'
ana 'bash alerts.sh v2.sql'

block staff
ana "sqlite3 -header -column siem.db \"SELECT timestamp, user, action FROM logs WHERE src_ip = '203.0.113.23' AND product = 'sshd'\""
