#!/usr/bin/env bash
# The machine every transcript in front-quality was recorded on, and how to
# repeat a recording.
#
# THE STUDENT NEVER RECEIVES THIS FILE. Lesson 1 builds the project by hand,
# step by step, and every later lesson shows in full each file it adds or the
# exact change it makes. This script, lab/ beside it and each lesson's
# captures.sh exist so the captures can be repeated and checked; none of them
# is a step of the course.
#
# THE PROJECT. ~/planner, the study planner: a plain TypeScript app built with
# Vite (the vanilla-ts template), with src/planner.ts, src/view.ts,
# src/main.ts and public/courses.json, served by `npm run dev` on port 5173.
# It is one git repository, and it grows from lesson to lesson: each lesson's
# capture starts from the tag the previous one left (lesson-N), so lesson 7
# can be recorded again without recording lessons 1 to 6, once they have been.
#
# WHAT IS STAGED, AND WHY
#   - The recording computer is Ubuntu 24.04 and every command runs as root,
#     in a private mount namespace (unshare --mount) where LAB_HOME/ana is
#     bound at /home/ana: the paths the programs print are /home/ana/..., as
#     on the machine the lessons describe, and the prompt `ana@dev` is
#     printed by capture-lib.sh rather than by a shell.
#   - Node.js is 22.22.0 with npm 10.9.4, the release javascript lesson 1
#     installs, from /opt/node22 rather than ~/.local/node.
#   - The browser is the Chromium build Playwright 1.63.0 names (1243,
#     Chrome for Testing 153.0.8010.12), already at /opt/pw-browsers, which
#     PLAYWRIGHT_BROWSERS_PATH points at. `npx playwright install` is shown in
#     lesson 4 as a step the student runs, and was not run here.
#   - npm's update notice and funding message are switched off, so the
#     transcripts do not depend on the day they were made; COLORS=false and
#     NO_COLOR=1 keep colour codes out of them, and the few a program writes
#     anyway (ts-jest's) are removed by capture-lib.sh's run().
#   - git knows ana as `ana <ana@planner.example>`, as the git course leaves
#     it, and every commit carries a fixed date, so the hashes repeat.
#   - TZ=America/Sao_Paulo and LC_ALL=C.UTF-8. Lesson 2 is about what the
#     time zone does to a date, so this one matters.
#   - A capture that starts a server stops it before it ends.
#
#   bash lab.sh fresh          delete the project: the next lesson-1 capture
#                              starts from no ~/planner at all
#   bash lab.sh shell          a shell inside the lab, as the captures see it
#   bash lab.sh capture N      run lesson N's captures.sh, output to stdout
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export LAB_HOME=${LAB_HOME:-/var/tmp/front-quality-home}
mkdir -p "$LAB_HOME/ana"
cat > "$LAB_HOME/ana/.gitconfig" <<'GIT'
[user]
	name = ana
	email = ana@planner.example
[init]
	defaultBranch = main
[advice]
	detachedHead = false
GIT

case "${1:-}" in
  fresh)   rm -rf "$LAB_HOME/ana/planner" "$LAB_HOME/ana/planner-jest" ;;
  shell)   exec unshare --mount bash -c "mount -t tmpfs tmpfs /home && mkdir /home/ana && mount --bind '$LAB_HOME/ana' /home/ana && cd /home/ana && HOME=/home/ana exec bash" ;;
  capture)
    id=$(python3 -c "import json,sys; print(json.load(open('$here/course.json'))['topics'][int(sys.argv[1])-1]['id'])" "$2")
    exec bash "$here/lessons/$id/captures.sh" ;;
  *) sed -n '2,45p' "$0"; exit 2 ;;
esac
