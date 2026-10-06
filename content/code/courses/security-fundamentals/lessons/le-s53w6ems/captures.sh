#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. ana@laptop
# plays the authenticator app on ana's phone, which the lab does not have:
# oathtool computes the same codes an app would. root@www is the server that
# checks them.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset. THE SECRET IS PUBLIC ON PURPOSE: it is the
# twenty bytes 12345678901234567890, the secret RFC 6238 uses for its own test
# vectors, written in base32. It protects nothing, and it lets the last block
# check oathtool against the specification. EVERY TIME IS GIVEN WITH --now, so
# the codes are the same on every run; a real authenticator uses the clock.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with oathtool 2.6.11, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
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
block() { printf '##### %s\n' "$1"; }
K=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ

lab reset

block steps
on laptop "oathtool --totp -b -v --now '2026-10-06 13:00:00 UTC' $K"

block codes
on laptop "oathtool --totp -b --now '2026-10-06 13:00:00 UTC' $K"
on laptop "oathtool --totp -b --now '2026-10-06 13:00:29 UTC' $K"
on laptop "oathtool --totp -b --now '2026-10-06 13:00:30 UTC' $K"

block check
root www "oathtool --totp -b --now '2026-10-06 13:00:00 UTC' $K 593771; echo \"exit \$?\""
root www "oathtool --totp -b --now '2026-10-06 13:02:00 UTC' $K 593771; echo \"exit \$?\""

block drift
on laptop "oathtool --totp -b --now '2026-10-06 12:59:45 UTC' $K"
root www "oathtool --totp -b --now '2026-10-06 13:00:00 UTC' $K 907684; echo \"exit \$?\""
root www "oathtool --totp -b -w 1 --now '2026-10-06 13:00:00 UTC' $K 907684; echo \"exit \$?\""

block rfc
on laptop "oathtool --totp -d 8 --now '1970-01-01 00:00:59 UTC' 3132333435363738393031323334353637383930"
