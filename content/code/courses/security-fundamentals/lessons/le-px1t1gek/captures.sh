#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# Everything happens on db, the server that holds the shop's data, as the
# administrator: root@db is the prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, which writes the shop's data under /srv/shop
# (data/ since March, invoices/ added later) and the backup job /root/backup.sh
# as it was written in March. The job fixes every date and owner in the archive
# and compresses with gzip -n, so the same data gives the same archive and the
# same hash on every run. Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
lab() { bash "$LAB_SH" "$@"; }
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab reset

block live
root db 'find /srv/shop -type f | sort'

block job
root db 'cat backup.sh'
root db './backup.sh 2026-10-04'
root db 'tar -tzf /backup/shop-2026-10-04.tar.gz'

block restore
root db 'mkdir restore && tar -xzf /backup/shop-2026-10-04.tar.gz -C restore'
root db 'diff -r /srv/shop restore; echo "exit $?"'

block fix
root db "sed -i 's/ data | gzip/ data invoices | gzip/' backup.sh"
root db 'tail -2 backup.sh'
root db './backup.sh 2026-10-05'
root db 'rm -r restore && mkdir restore && tar -xzf /backup/shop-2026-10-05.tar.gz -C restore'
root db 'diff -r /srv/shop restore; echo "exit $?"'

block sums
root db 'sha256sum /backup/shop-2026-10-05.tar.gz > /backup/SHA256SUMS'
root db 'sha256sum -c /backup/SHA256SUMS'

block corrupt
root db 'cp /backup/shop-2026-10-05.tar.gz offsite.tar.gz'
root db 'printf X | dd of=offsite.tar.gz bs=1 seek=200 conv=notrunc 2>/dev/null'
root db 'cat /backup/SHA256SUMS; sha256sum offsite.tar.gz'
