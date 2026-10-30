#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of mobile-offline (files).
#
#   sudo bash captures.sh > out.txt
#
# Needs lab.sh's machine and lesson 1's ~/planner (package.json and
# better-sqlite3), and the sqlite3 shell lesson 3 installs. Works in
# ~/planner/files only. Every .ts is taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - server.ts runs in the background; "download-log" is what it printed,
#     shown under the command that started it, as in its own terminal.
#   - The 999999 MB request in "full" is larger than any disk, so the same
#     refusal comes back on every computer.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/files
LAB as 'rm -rf ~/planner/files && mkdir -p ~/planner/files'
put files-not-blobs.md attach.ts $D/attach.ts
put downloads-that-resume.md server.ts $D/server.ts
put downloads-that-resume.md download.ts $D/download.ts
put disk-full.md save.ts $D/save.ts
put orphans.md sweep.ts $D/sweep.ts

block attach
run $D 'node attach.ts blob'
run $D 'node attach.ts file'
run $D 'ls attachments'

block download
serve $D 8018 'node server.ts'
run $D 'node download.ts'
run $D 'ls'
run $D 'node download.ts'
run $D 'ls'

block download-log
printf 'ana@dev:~/planner/files$ node server.ts\n'
cat "$LOGF"
unserve

block full
LAB as "rm -rf $D/attachments $D/files.db"
run $D 'node save.ts notes.pdf 5 /dev/full'
run $D 'node save.ts notes.pdf 5'
run $D 'node save.ts atlas.pdf 999999'
run $D 'sqlite3 files.db "select * from attachments"'

block sweep
run $D 'node save.ts guitar-tabs.pdf 1'
run $D 'node save.ts spanish-verbs.pdf 2'
run $D "sqlite3 files.db \"delete from attachments where name = 'guitar-tabs.pdf'\""
run $D 'rm attachments/notes.pdf'
run $D 'node sweep.ts'
run $D 'node sweep.ts'
