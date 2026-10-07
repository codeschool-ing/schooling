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
