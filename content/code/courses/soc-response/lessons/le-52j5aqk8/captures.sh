#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, plus ewf-tools from lesson 16 and
# gdb, which this lesson installs. Commands at the root@soc prompt run as root,
# in /root/case, each with a clean environment.
#
# STAGED, NOT TYPED: lesson 16's disk and raw image are made again first, by
# running that lesson's own commands (make_disk.py, mke2fs, debugfs, losetup,
# dd) without printing them, so /root/case/evidence/files-data.dd is the image
# lesson 16 ends with. holder.py, beside this script, is the program the lesson
# prints and tells the student to write; it is copied into /root/case. The
# holder process is stopped at the end.
#
# Recorded on Ubuntu 24.04 with The Sleuth Kit 4.11.1, xxd 2023-10-25 and
# GDB 15.0.50, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~/case# %s\n' "$*"; (cd /root/case && env -i $ENV bash -c "$*") 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root/case && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

for dev in $(losetup -j /root/case/disk.img -O NAME -n 2>/dev/null); do losetup -d "$dev"; done
rm -rf /root/case; mkdir -p /root/case/evidence
install -m 644 "$HERE/../le-c7db28gx/make_disk.py" "$HERE/holder.py" /root/case/
quiet 'python3 make_disk.py && mke2fs -q -t ext4 -L files-data -d data disk.img 32M'
quiet "debugfs -w -R 'rm exports/contacts-2026-08.csv' disk.img"
LOOP=$(losetup --read-only --find --show /root/case/disk.img)
dd if="$LOOP" of=/root/case/evidence/files-data.dd bs=4M conv=noerror,sync status=none
losetup -d "$LOOP"

block copy
root 'cp evidence/files-data.dd work.dd'
root 'sha256sum evidence/files-data.dd work.dd'

block fsstat
root 'fsstat work.dd | head -5'
root "fsstat work.dd | grep -E '^(Block Size|Block Range|Free Blocks)'"

block fls
root 'fls -r -p work.dd'

block deleted
root 'fls -r -d -p work.dd'
root "istat work.dd 24 | sed -n '1,2p;7,8p;10,19p'"

block recover
root 'icat work.dd 24 > recovered-contacts.csv'
root 'cat recovered-contacts.csv'
root 'sha256sum recovered-contacts.csv'

block hex
root 'blkcat work.dd 1561 | xxd | head -6'

block timeline
root 'fls -r -m / work.dd > body.txt'
root "mactime -b body.txt -d -y -z UTC 2>/dev/null | grep -E '^Date|exports'"

block memory
root 'python3 holder.py > holder.pid &'
sleep 1
root 'cat holder.pid'
root 'gcore -o mem $(cat holder.pid) 2>&1 | tail -2'
root 'ls -l mem.*'
root "strings mem.* | grep -m 1 '^session-'"
root 'sha256sum mem.*'

quiet 'kill $(cat holder.pid)'
