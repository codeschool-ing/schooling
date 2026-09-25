#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset: its root CA, trusted by every
# machine in the lab, signs an issuing CA, which signs www.example.com; the
# same nginx also serves four names with broken certificates, expired,
# selfsigned, nochain (sent without its intermediate) and intranet (signed
# by the office's own CA); the office CA's certificate copied into ana's
# home on laptop before the intranet block, as a colleague would send it.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset

block fields
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName,basicConstraints,extendedKeyUsage'

block chain
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>&1 | grep -E "^depth|^ *[0-9] s:|^ *i:|Verify return"'

block store
on laptop 'ls /etc/ssl/certs/*.pem | wc -l'
on laptop 'grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt'
on laptop 'openssl x509 -in /etc/ssl/certs/example-root-ca.pem -noout -subject -issuer -enddate'

block csr
on server 'openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=files.example.com" -keyout files.key -out files.csr 2>/dev/null; ls -l files.key files.csr'
on server 'openssl req -in files.csr -noout -subject -verify'
on server 'head -1 files.key; head -1 files.csr'

block expired
on laptop 'curl -sS -o /dev/null https://expired.example.com/'
on laptop 'openssl s_client -connect expired.example.com:443 -servername expired.example.com </dev/null 2>/dev/null | openssl x509 -noout -dates'

block selfsigned
on laptop 'curl -sS -o /dev/null https://selfsigned.example.com/'
on laptop 'openssl s_client -connect selfsigned.example.com:443 -servername selfsigned.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer'

block wrongname
on laptop 'curl -sS -o /dev/null --resolve wrong.example.com:443:192.0.2.80 https://wrong.example.com/'

block nochain
on laptop 'curl -sS -o /dev/null https://nochain.example.com/'
on laptop 'openssl s_client -connect nochain.example.com:443 -servername nochain.example.com </dev/null 2>&1 | grep -E "^ *[0-9] s:|^ *i:|Verify return"'

block verify-codes
on laptop 'for h in expired selfsigned nochain; do printf "%-11s " $h; openssl s_client -connect $h.example.com:443 -servername $h.example.com </dev/null 2>/dev/null | grep "Verify return"; done'

block intranet
on laptop 'curl -sS -o /dev/null https://intranet.example.com/'
# The office CA's certificate, as a colleague would send it, into ana's home on laptop.
sudo install -o ana -g ana -m 644 /lab/ca/office.crt /lab/laptop/home/ana/office-ca.crt
on laptop 'openssl x509 -in office-ca.crt -noout -subject -issuer -fingerprint -sha256'
on laptop 'sudo cp office-ca.crt /usr/local/share/ca-certificates/example-office-ca.crt'
on laptop 'sudo update-ca-certificates'
on laptop "curl -sS -o /dev/null -w '%{http_code}\n' https://intranet.example.com/"

block expiry
on laptop 'echo | openssl s_client -connect www.example.com:443 -servername www.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 2592000'
on laptop 'echo | openssl s_client -connect expired.example.com:443 -servername expired.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 0'

lab down
