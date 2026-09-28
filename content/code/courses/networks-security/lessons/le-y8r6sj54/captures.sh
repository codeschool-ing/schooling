#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/nslab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@admin is the administrator on the management machine, which holds the
# company's certificate authority in this lab.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the company's CA, which lab.sh builds with fixed dates (a root,
# an issuing CA and www.example.com's certificate), copied to admin's
# /root/ca with its openssl ca configuration; the certificate for app copied
# to app and to laptop between blocks, as it would be installed and fetched.
# In a real company the root's private key would not be on any networked
# machine at all; the lesson says so where it matters.
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
cp -a /lab/ca /lab/admin/root/ca; sed -i "s#^dir = .*#dir = /root/ca#" /lab/admin/root/ca/ca.cnf; rm -f /lab/admin/root/ca/*.csr

block fields
root admin 'cd ca; for c in root issuing www.example.com; do echo "== $c"; openssl x509 -in $c.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage,extendedKeyUsage,subjectAltName 2>/dev/null; done'

block chain
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *[0-9] s:|^ *i:|^Verify return code"'

block verify
root admin 'cd ca; openssl verify -CAfile root.crt www.example.com.crt'
root admin 'cd ca; openssl verify -CAfile root.crt -untrusted issuing.crt www.example.com.crt'
root admin 'cd ca; openssl verify -CAfile issuing.crt www.example.com.crt'

block issue
root admin 'cd ca; openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=app.corp.example.com" -keyout app.key -out app.csr 2>/dev/null; openssl req -in app.csr -noout -subject -verify'
quiet admin 'cd ca; { sed -n "/^\[server\]/,/^\[/p" ca.cnf | sed "\$d"; echo "subjectAltName = DNS:app.corp.example.com"; } > app.ext'
root admin 'cd ca; cat app.ext'
root admin 'cd ca; openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile app.ext -extensions server -startdate 20260928000000Z -enddate 20261228000000Z -in app.csr -out app.crt -notext 2>&1 | grep -E "Signature ok|Data Base"'
root admin 'cd ca; openssl x509 -in app.crt -noout -serial -subject -issuer -dates -ext subjectAltName'
root admin 'cd ca; tail -2 index.txt'

block revoke
root admin 'cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -revoke app.crt -crl_reason keyCompromise 2>&1 | tail -1'
root admin 'cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -gencrl -crldays 7 -out issuing.crl 2>/dev/null; openssl crl -in issuing.crl -noout -text | grep -E "Last Update|Next Update|Serial Number|Revocation Date|Key Compromise"'
root admin 'cd ca; cat issuing.crt root.crt > chain.pem; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl app.crt; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl www.example.com.crt'
root admin 'cd ca; tail -2 index.txt'

block trust-store
on laptop 'ls -l /etc/ssl/certs/ | grep -i example; openssl x509 -in /etc/ssl/certs/example-corp-root-ca.pem -noout -subject -fingerprint -sha256'
