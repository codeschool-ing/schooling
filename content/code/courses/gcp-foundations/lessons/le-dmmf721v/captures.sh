#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), which on
# Ubuntu Server 24.04 includes the OpenSSH client gcloud needs for
# `cloud-shell ssh`. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: the SSH key
# gcloud makes, ~/.ssh/google_compute_engine, is removed before the block
# `dryrun`, so that every recording shows the first run, which is the one the
# prose describes. The prose shows the grep that keeps only the lines that do
# not change from run to run: the key's fingerprint and its picture do.
#
# REACHES GOOGLE: one block, `dryrun`, which asks the Cloud Shell API to start
# the machine with the placeholder token, and is refused.
#
# NOT PRODUCED HERE, and said so in the prose: Cloud Shell itself, its editor,
# its preview and .customize_environment.
#
# `size` IS EXPECTED TO DIFFER: the lab's home grows with every lesson recorded
# after this one, and the prose quotes the total only roughly, "about a
# gigabyte and a quarter".
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
cd ~/gcp && at '~/gcp'

block commands
run 'gcloud cloud-shell --help | sed -n "/^COMMANDS/,/^NOTES/p" | grep -E "^     [a-z]"'
block size
run 'cd ~ && du -sh .local gcp'

rm -f ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine.pub
net
block dryrun
run 'gcloud cloud-shell ssh --dry-run 2>&1 | grep -E "^(Automatic|WARNING|ERROR|Your)"'
