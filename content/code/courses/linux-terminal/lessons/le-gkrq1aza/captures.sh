#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs.
# --setup runs the `sh` fences as the page shows them: the teaching repository
# in dnf-and-yum.md (dnf, zypper, rpm and createrepo-c from Ubuntu, two specs,
# rpmbuild, createrepo_c) and its zypper entry in zypper.md.
#
#   sudo bash captures.sh
#
# The transcripts are the first capture's. Replayed on 2026-10-07 with the specs
# above, dnf and zypper print the same packages, the same installed size (89
# bytes) and the same dependency; what differs is the width (80 columns through a
# pipe against the 100 of the first capture's terminal), a few hundred bytes of
# package size, and dates. The apt sections show that machine's own sources
# (Docker's repository and two PPAs its proxy refused) and installed packages,
# and the prose says so.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 7
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
