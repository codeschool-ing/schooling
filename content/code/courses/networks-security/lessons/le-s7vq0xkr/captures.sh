#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of networks-security, as a script that produces them.
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
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; a release file, agent-2.4.1.tar.gz, and its checksum list
# placed in www's document root, served by nginx under /downloads/; the
# public half of admin's signing key copied to laptop, as it would be
# published once, in advance, on a channel people already trust.
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
quiet www 'mkdir -p /var/www/downloads; cd /var/www/downloads; head -c 20000 /dev/zero | tr "\0" "a" > agent-2.4.1.tar.gz; sha256sum agent-2.4.1.tar.gz > SHA256SUMS'
quiet www 'sed -i "s|    location / {|    location /downloads/ {\n        root /var/www;\n    }\n    location / {|" /etc/nginx/sites-enabled/shop; nginx -s reload'
sleep 1

block hashes
on laptop 'printf "transfer 100 to 4471\n" | sha256sum'
on laptop 'printf "transfer 900 to 4471\n" | sha256sum'
on laptop 'head -c 1000000 /dev/zero | sha256sum; printf "" | sha256sum'

block download
on laptop 'curl -sO https://www.example.com/downloads/agent-2.4.1.tar.gz; curl -sO https://www.example.com/downloads/SHA256SUMS; cat SHA256SUMS'
on laptop 'sha256sum -c SHA256SUMS'
on laptop 'printf "x" >> agent-2.4.1.tar.gz; sha256sum -c SHA256SUMS; echo "exit $?"'

block hmac
on laptop 'printf "order=17&status=paid" | openssl dgst -sha256 -hmac "shared-webhook-secret"'
on laptop 'printf "order=17&status=paid" | openssl dgst -sha256 -hmac "a-guessed-secret"'

block sign
on admin 'openssl genpkey -algorithm ed25519 -out release.key; openssl pkey -in release.key -pubout -out release.pub; cat release.pub'
quiet www 'true'
cp /lab/www/var/www/downloads/agent-2.4.1.tar.gz /lab/admin/home/ana/; chown ana:ana /lab/admin/home/ana/agent-2.4.1.tar.gz
on admin 'openssl pkeyutl -sign -rawin -inkey release.key -in agent-2.4.1.tar.gz -out agent-2.4.1.tar.gz.sig; wc -c agent-2.4.1.tar.gz.sig'
cp /lab/admin/home/ana/release.pub /lab/admin/home/ana/agent-2.4.1.tar.gz.sig /lab/laptop/home/ana/; cp /lab/admin/home/ana/agent-2.4.1.tar.gz /lab/laptop/home/ana/agent-2.4.1.tar.gz; chown ana:ana /lab/laptop/home/ana/*
on laptop 'openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig'
on laptop 'printf "x" >> agent-2.4.1.tar.gz; openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig; echo "exit $?"'

block hostkey
root app 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
on admin 'ssh-keyscan -t ed25519 app 2>/dev/null | ssh-keygen -lf -'
on admin 'ssh -o BatchMode=yes app true 2>&1 | head -3'
