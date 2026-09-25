#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of networks, as a script that produces them.
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
# the lab itself, built by lab.sh reset: two mail servers, mail for
# example.com (192.0.2.25) and netmail for example.net (192.0.2.26), each
# with Postfix, Dovecot, OpenDKIM signing its own domain and OpenDMARC
# checking what arrives; ana's mailbox on mail (password office-2026) and
# bruno's on netmail. Before the reply block, bruno's answer sent from
# netmail with sendmail; before the queue block, netmail's Postfix
# stopped, and started again before the queue is flushed.
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

cat > /tmp/typed-shell.sh <<'SH'
printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.$$
INPUTRC=/tmp/inputrc.$$ script -qec "env PS1='\u@\h:\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null
rm -f /tmp/inputrc.$$
SH
typed() {
  local h=$1 cmds; cmds=$(cat)
  { sleep 1; while IFS= read -r l; do printf '%s\n' "$l"; sleep "${PAUSE:-1.5}"; done <<< "$cmds"; printf 'exit\n'; sleep 0.5; } |
    timeout 120 sudo bash "$LAB_SH" exec "$h" ana 'bash /tmp/typed-shell.sh' | sed '$d' | sed '$d'
}

lab reset
# Ana's message, written as her mail program would write it.
lab exec laptop ana 'printf "Date: Fri, 25 Sep 2026 10:02:00 -0300\r\nMessage-ID: <order-2231@example.com>\r\nFrom: Ana <ana@example.com>\r\nTo: Bruno <bruno@example.net>\r\nSubject: Order 2231\r\n\r\nHello Bruno, can you confirm order 2231?\r\n" > order.txt'

block mx
on laptop 'dig +short MX example.net'
on laptop 'dig +short A mail.example.net'

block by-hand
(PAUSE=2 typed mail <<'IN'
nc -C mail.example.net 25
EHLO mail.example.com
MAIL FROM:<ana@example.com>
RCPT TO:<bruno@example.net>
DATA
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Delivery on Monday

The boxes arrive on Monday.
.
QUIT
IN
) | sed '${/^exit\r*$/d}'

block relay
on laptop 'swaks --to bruno@example.net --from ana@example.com --server mail.example.com --quit-after RCPT'

block submission
on laptop 'cat order.txt'
on laptop 'curl -sS -v --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt bruno@example.net -T order.txt 2>&1 | grep -E "^[<>] " | grep -vE "^< 250-(PIPELINING|SIZE|VRFY|ETRN|ENHANCEDSTATUSCODES|8BITMIME|DSN|SMTPUTF8|CHUNKING)"'
on laptop 'echo AGFuYQBvZmZpY2UtMjAyNg== | base64 -d | tr "\0" " "; echo'
sleep 8

block headers
on netmail 'sudo doveadm fetch -u bruno hdr subject "Order 2231"'

block reply
lab exec netmail bruno 'printf "Date: Fri, 25 Sep 2026 10:15:00 -0300\nMessage-ID: <re-2231@example.net>\nIn-Reply-To: <order-2231@example.com>\nFrom: Bruno <bruno@example.net>\nTo: Ana <ana@example.com>\nSubject: Re: Order 2231\n\nConfirmed, it ships on Monday.\n" | /usr/sbin/sendmail -t' >/dev/null 2>&1
sleep 8
on laptop 'dig +short MX example.com'

block imap
PAUSE=2 typed laptop <<'IN'
openssl s_client -connect mail.example.com:993 -crlf -quiet
a1 LOGIN ana office-2026
a2 SELECT INBOX
a3 FETCH 1 (BODY[HEADER.FIELDS (FROM SUBJECT DATE)])
a4 FETCH 1 BODY[TEXT]
a5 LOGOUT
IN

block pop3
PAUSE=2 typed laptop <<'IN'
openssl s_client -connect mail.example.com:995 -crlf -quiet
USER ana
PASS office-2026
STAT
LIST
QUIT
IN

block spf
on laptop 'dig +short TXT example.com'
on laptop 'dig +short TXT example.net'

block dkim
on laptop 'dig +short TXT mail._domainkey.example.com | cut -c1-90'
on netmail 'sudo doveadm fetch -u bruno hdr.authentication-results subject "Order 2231"'

block dmarc
on laptop 'dig +short TXT _dmarc.example.net'
on home 'swaks --to ana@example.com --from bruno@example.net --server mail.example.com --header "Subject: Invoice overdue" --body "Please pay to the new account."'

block bounce
lab exec laptop ana 'sed "s/Bruno <bruno@example.net>/<brunno@example.net>/; s/order-2231/order-2231b/" order.txt > wrong.txt'
on laptop 'curl -sS --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt brunno@example.net -T wrong.txt && echo accepted'
sleep 8
on mail 'sudo doveadm fetch -u ana hdr.subject subject "Undelivered"'
on mail 'sudo doveadm fetch -u ana body subject "Undelivered" | sed -n "/^This is the mail system/,/RCPT TO command)/p"'

block queue
sudo bash "$LAB_SH" exec netmail root 'postfix stop' >/dev/null 2>&1
lab exec laptop ana 'sed "s/order-2231/order-2231c/; s/Subject: Order 2231/Subject: Order 2231, corrected/" order.txt > again.txt'
on laptop 'curl -sS --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt bruno@example.net -T again.txt && echo accepted'
sleep 3
on mail 'sudo postqueue -p'
sudo bash "$LAB_SH" exec netmail root 'postfix start' >/dev/null 2>&1
sleep 2
on mail 'sudo postqueue -f'
sleep 6
on mail 'sudo postqueue -p'
on mail 'sudo grep -oE "to=<[^>]+>.*status=[a-z]+" /var/log/mail/postfix.log'

lab down >/dev/null 2>&1
