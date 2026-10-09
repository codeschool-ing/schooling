#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, plus ewf-tools, which this lesson
# installs. Commands at the root@soc prompt run as root, in /root/case, each
# with a clean environment.
#
# STAGED, NOT TYPED: make_disk.py, beside this script, is the program the
# lesson prints and tells the student to write; it is copied into /root/case,
# which is emptied first. Any loop device left from an earlier run is detached.
# The disk image's UUID and time stamps come from the moment it is made, so
# every hash differs from run to run; the lesson quotes them only as this run's.
#
# Recorded on Ubuntu 24.04 with e2fsprogs 1.47.0, coreutils 9.4 and
# ewf-tools 20140814, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~/case# %s\n' "$*"; (cd /root/case && env -i $ENV bash -c "$*") 2>&1; }
block() { exec >"$OUT/$1.txt"; }

for dev in $(losetup -j /root/case/disk.img -O NAME -n 2>/dev/null); do losetup -d "$dev"; done
rm -rf /root/case; mkdir -p /root/case
install -m 644 "$HERE/make_disk.py" /root/case/

block disk
root 'python3 make_disk.py'
root 'mke2fs -q -t ext4 -L files-data -d data disk.img 32M'
root "debugfs -w -R 'rm exports/contacts-2026-08.csv' disk.img"
root 'ls -l disk.img'

block attach
root 'losetup --read-only --find --show disk.img'
root 'blockdev --getro /dev/loop0'
root 'dd if=/dev/zero of=/dev/loop0 count=1'

block dd
root 'mkdir evidence'
root 'sha256sum /dev/loop0'
root 'dd if=/dev/loop0 of=evidence/files-data.dd bs=4M conv=noerror,sync'
root 'sha256sum evidence/files-data.dd'

block ewf
root "ewfacquire -u -q -t evidence/files-data -C INC-2026-014 -E 001 -D 'files, data disk' -e diego -N 'imaged after containment' -d sha256 -c deflate:fast /dev/loop0"
root 'ls -l evidence'

block verify
root 'ewfverify -q evidence/files-data.E01'
root 'ewfinfo evidence/files-data.E01'
