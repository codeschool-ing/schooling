#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs.
# --setup-home runs the block that writes server.conf, notes.txt and list.txt
# into ~/work/edit; the `wc -lc` transcript under it checks them against the
# sizes the editor screens report (server.conf is 6L, 101B in vim).
#
# The editor screens themselves are figures, captured from a real terminal and
# checked against the file on disk when they were made; this replay does not
# redraw them. An Ubuntu 24.04 guest was asked what `vi`, `vimtutor`, `nano` and
# the `editor` alternative are there, and they agree with what the lesson says.
#
#   sudo bash captures.sh
#
# Expected to differ: the dates on the /usr/bin/vi symlinks.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 12
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup-home $sections
