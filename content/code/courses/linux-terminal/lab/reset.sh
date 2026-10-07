#!/usr/bin/env bash
# Put the capture machine's `ana` back to a freshly installed account, so a
# lesson replays from the state its first section assumes. The author's tool.
#
# `ana` is uid 1001 because this machine already had an account at 1000, and the
# transcripts say so. She is in `sudo`, as an installer's first user is, with a
# password replay.py types when sudo asks.
set -euo pipefail
pkill -u ana 2>/dev/null || true
userdel -r ana 2>/dev/null || true
getent group ana >/dev/null || groupadd -g 1002 ana
useradd -m -u 1001 -g 1002 -G sudo -s /bin/bash ana
echo 'ana:ana-lab-password' | chpasswd

# What the lessons make outside ana's home, so a replay starts from nothing.
for u in bruno carla demo dora; do
  pkill -u "$u" 2>/dev/null || true
  userdel -r "$u" 2>/dev/null || true
done
umount /mnt/backups 2>/dev/null || true
rm -rf /root/img /mnt/backups
losetup -D 2>/dev/null || true
for g in team deploy bruno carla demo dora; do groupdel "$g" 2>/dev/null || true; done
rm -rf /srv/perm /srv/closed /srv/dirbits /srv/team /tmp/anas.txt /tmp/newgrp-test.txt /root/marker.txt
# A stock Ubuntu has no group above the ordinary range, and this sandbox has
# one at 30001; capped here, groupadd numbers the course's groups the way a
# fresh machine would, 1003 onwards, which is what the transcripts show.
sed -i 's/^GID_MAX\t\t\t60000/GID_MAX\t\t\t30000/' /etc/login.defs
