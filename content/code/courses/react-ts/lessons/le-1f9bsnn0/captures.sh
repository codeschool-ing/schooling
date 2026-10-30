#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of react-ts, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo -E bash ../../lab.sh up       # once: the user, Node.js, look
#   sudo -E bash captures.sh
#
# What is STAGED rather than typed:
#   - ~/react-tools and the look command, which the lab builds from this
#     lesson's own look.mjs (the "look" section shows every step of it);
#   - the browser: Playwright's Chromium 1243 is already in /opt/pw-browsers,
#     so `npx playwright install` is not run here (the lesson says so);
#   - the files ana wrote, put below and shown whole in the lesson;
#   - the second `npm run dev` of "When the setup fails", which runs under
#     `timeout 8` so that the script can go on, and is shown without it.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab reset >/dev/null

CWD=
block node
on 'node --version'
on 'npm --version'
on 'command -v node'
on 'npm config set update-notifier false'

block create
# A fresh npx cache, as on a computer that never ran create-vite.
lab exec ana 'rm -rf ~/.npm/_npx'
on 'npm create vite@9.3.1 planner -- --template react-ts --no-interactive'
CWD=planner
on 'ls -A'
on 'cat package.json'
on 'cat src/main.tsx'

block pin
on 'npm config set save-exact true --location=project'
on 'cat .npmrc'
on 'npm install react@19.3.1 react-dom@19.3.1'
on 'npm install --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0'
on 'cat package.json'
on 'npm ls'
on 'ls -A'

block dev
serve 5173 npm run dev
prompt; echo 'npm run dev'
served
on 'curl -s http://localhost:5173/ | head -n 12'

block look-tools
# ~/react-tools is built here the way the lesson tells the student to, after
# the lab's own copy is moved out of the way.
lab exec ana 'rm -rf ~/react-tools ~/.local/bin/look'
CWD=
on 'mkdir ~/react-tools'
CWD=react-tools
on 'npm init -y'
on 'npm install --save-exact playwright@1.63.0'
# STAGED: the dry run is asked with PLAYWRIGHT_BROWSERS_PATH unset, as it is on
# a student's machine, so that it names the folder a student's download goes to.
prompt; echo 'npx playwright install --dry-run --only-shell chromium'
run 'env -u PLAYWRIGHT_BROWSERS_PATH npx playwright install --dry-run --only-shell chromium'
put look.mjs < <(node ../../lab/extract.mjs look.md look.mjs)
CWD=
put .local/bin/look <<'SH'
#!/bin/sh
exec node ~/react-tools/look.mjs "$@"
SH
on 'chmod +x ~/.local/bin/look'
CWD=planner
on 'look http://localhost:5173/'
on "look http://localhost:5173/ --do 'click button Count is 0' --do 'click button Count is 1'"

block planner-data
put public/courses.json <<'JSON'
{
  "courses": [
    { "id": "statistics", "name": "Statistics" },
    { "id": "spanish", "name": "Spanish" },
    { "id": "chemistry", "name": "Organic chemistry" }
  ],
  "sessions": [
    { "id": "s1", "course": "statistics", "date": "2026-10-19", "minutes": 50, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-21", "minutes": 40, "done": false },
    { "id": "s3", "course": "spanish", "date": "2026-10-20", "minutes": 30, "done": true },
    { "id": "s4", "course": "spanish", "date": "2026-10-23", "minutes": 30, "done": false },
    { "id": "s5", "course": "chemistry", "date": "2026-10-14", "minutes": 60, "done": true },
    { "id": "s6", "course": "chemistry", "date": "2026-10-22", "minutes": 45, "done": false }
  ]
}
JSON
on 'curl -s http://localhost:5173/courses.json | head -n 5'

block enoent
CWD=
on 'npm run dev'
CWD=planner
block port
lab exec ana 'cd ~/planner && timeout 8 npm run dev' > /tmp/rtlab-second.out 2>&1
prompt; echo 'npm run dev'; cat /tmp/rtlab-second.out
block nobrowser
# STAGED: the browser is hidden by pointing Playwright at an empty folder,
# which is what a computer that never downloaded one looks like to it. The
# lesson shows the command as `look http://localhost:5173/`.
prompt; echo 'look http://localhost:5173/'
run 'PLAYWRIGHT_BROWSERS_PATH=$HOME/no-browser-here look http://localhost:5173/ 2>&1 | head -n 12'
block typo
on "sed -i \"1s/'react'/'reakt'/\" src/App.tsx"
on 'head -n 1 src/App.tsx'
on 'look http://localhost:5173/'
block typo-server
# The first of the messages the server printed; it repeats it for each request.
served | sed -n '/Pre-transform error/,+6p' | head -n 7
block fixed
on "sed -i \"1s/'reakt'/'react'/\" src/App.tsx"
on 'look http://localhost:5173/ --quiet'
block refused
stop
on 'look http://localhost:5173/ 2>&1 | head -n 6'

lab save after-$(basename "$PWD")
finish
