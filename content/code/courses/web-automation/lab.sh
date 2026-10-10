#!/usr/bin/env bash
# The lab behind every transcript in web-automation.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). The project every lesson drives is
# quitanda: a small shop written in Node with no dependencies, with known
# flaws put there on purpose, and a Playwright project beside it. The student
# builds all of it from the lessons. Every file is shown whole in the section
# that introduces it, behind a paragraph ending "as `PATH`:", and this script
# builds the project FROM THOSE BLOCKS, so a lesson and the lab cannot differ:
#
#   bash lab.sh stage N [DIR]     rebuild DIR (default /home/ana/quitanda) with
#                                 every file lessons 1..N show, in course order
#                                 and section order, a later block replacing an
#                                 earlier one at the same path; then the npm
#                                 packages lessons 1..N install
#   bash lab.sh files N           which lesson and section wrote each file
#   bash lab.sh fence SECTION.md PATH
#                                 print the block SECTION.md labels PATH, for a
#                                 capture that needs a version a later section
#                                 replaced
#
# Captures source it for the helpers below (`source lab.sh lib`), and every
# capture runs inside one lock, because they share /home/ana/quitanda and the
# port 3000 the transcripts print.
#
# THE MACHINE. Ubuntu 24.04, Node 22.22.0 and npm 10.9.4, run as the user ana
# with HOME=/home/ana, TZ=America/Sao_Paulo. Staged rather than done the way a
# student does it, and said in each captures.sh that meets it:
#   - the browsers. `npx playwright install chromium` downloads Chromium 141
#     (Playwright's build 1194) into ~/.cache/ms-playwright; this sandbox
#     cannot reach that download, so the same build is copied there from the
#     sandbox's own copy at /opt/pw-browsers. Firefox and WebKit could not be
#     obtained at all, and every lesson that names them says so.
#   - Selenium's driver. Selenium Manager downloads a chromedriver matching the
#     browser; it cannot here either, so chromedriver 141.0.7390.122 comes from
#     the chromedriver-py wheel on PyPI and sits in ~/bin with a `google-chrome`
#     link to the same Chromium 141, which is where Selenium Manager looks.
#   - Cypress. Its binary is a separate download the sandbox cannot reach, and
#     nothing in lesson 9 was run.
set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export ANA_HOME=/home/ana
REPO_DEFAULT=$ANA_HOME/quitanda
NODE_BIN=/opt/node22/bin

lessons() {
  python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["lessons"]))' "$COURSE/course.json"
}

# Every labelled block of lessons 1..N as "lesson section path", in order.
blocks() {
  python3 - "$COURSE" "$1" "${2:-}" <<'PY'
import json, re, sys
from pathlib import Path
course, n, out = Path(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
lessons = json.load(open(course / "course.json"))["lessons"][:n]
written = {}
for i, lid in enumerate(lessons, 1):
    d = course / "lessons" / lid
    if not (d / "lesson.json").exists():
        continue
    for s in json.load(open(d / "lesson.json"))["sections"]:
        md = d / (s["slug"] + ".md")
        if not md.exists():
            continue
        lines = md.read_text().split("\n")
        k, prev, ended = 0, "", False
        while k < len(lines):
            m = re.match(r"^(`{3,})(\S*)\s*$", lines[k])
            if not m:
                if not lines[k].strip():
                    ended = True
                else:
                    prev = lines[k].strip() if ended else prev + " " + lines[k].strip()
                    ended = False
                k += 1
                continue
            j = k + 1
            while lines[j].rstrip() != m.group(1):
                j += 1
            label = re.search(r"\bas `([\w./-]+)`:$", prev.rstrip())
            if label:
                body = "\n".join(lines[k + 1:j])
                if m.group(2) == "schooling-example":
                    body = "\n".join(p["code"] for p in json.loads(body)["parts"])
                written[label.group(1)] = (i, s["slug"], body + "\n")
            prev, k = "", j + 1
for path, (i, slug, body) in written.items():
    if out:
        f = Path(out) / path
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(body)
    else:
        print(f"lesson {i:2} {slug:24} {path}")
PY
}

stage() {
  local n=$1 dir=${2:-$REPO_DEFAULT}
  case $dir in /home/ana/*) ;; *) echo "stage: $dir is not under /home/ana" >&2; return 1 ;; esac
  rm -rf -- "$dir"
  mkdir -p -- "$dir"
  blocks "$n" "$dir" || return 1
  if [ -f "$dir/package.json" ]; then
    npm_in "$dir" install --no-audit --no-fund >/dev/null 2>&1 \
      || { echo "stage: npm install failed in $dir" >&2; return 1; }
  fi
  chown -R ana:ana "$dir"
}

fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
lines, want = open(sys.argv[1]).read().split("\n"), sys.argv[2]
i, prev, ended = 0, "", False
while i < len(lines):
    m = re.match(r"^(`{3,})(\S*)\s*$", lines[i])
    if not m:
        if not lines[i].strip():
            ended = True
        else:
            prev = lines[i].strip() if ended else prev + " " + lines[i].strip()
            ended = False
        i += 1
        continue
    j = i + 1
    while lines[j].rstrip() != m.group(1):
        j += 1
    label = re.search(r"\bas `([\w./-]+)`:$", prev.rstrip())
    if label and label.group(1) == want:
        print("\n".join(lines[i + 1:j]))
        sys.exit(0)
    prev, i = "", j + 1
sys.exit(f"fence: {sys.argv[1]} labels no block {want}")
PY
}

# ---- what a captures.sh uses -------------------------------------------------

# npm is the one thing here that needs the network, and the registry is
# reached through the sandbox's proxy, whose settings belong to root. So npm
# runs as root, in ana's directory, and the files are handed to her after.
npm_in() {
  local dir=$1; shift
  (cd "$dir" && PATH=$NODE_BIN:$PATH npm "$@")
  local status=$?
  chown -R ana:ana "$dir"
  return $status
}
# The same, printed as the line ana typed.
run_npm() {
  local dir=$REPO_DEFAULT
  printf 'ana@laptop:~/quitanda$ npm %s\n' "$*"
  npm_in "$dir" "$@" 2>&1
}

# A command as ana, in a login-like environment: her PATH, her HOME, no proxy
# variables a fresh laptop would not have, Playwright looking where it looks
# by default.
as_ana() {
  su ana -s /bin/bash -c "env -i HOME=$ANA_HOME USER=ana LOGNAME=ana SHELL=/bin/bash \
    TERM=dumb LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo \
    PATH=$ANA_HOME/bin:$NODE_BIN:/usr/local/bin:/usr/bin:/bin \
    npm_config_cache=$ANA_HOME/.npm npm_config_update_notifier=false \
    bash -c $(printf '%q' "$1")"
}

block() { printf '##### %s\n' "$1"; }

# Print the prompt and the command, then run it in DIR (default the project).
run_in() {
  local dir=$1; shift
  local shown=${dir/#$ANA_HOME/\~}
  printf 'ana@laptop:%s$ %s\n' "$shown" "$*"
  as_ana "cd '$dir' && $*" 2>&1
}
run() { run_in "$REPO_DEFAULT" "$@"; }

# The app in the background, for a capture that drives it by hand rather
# than through Playwright's webServer. Stopped by pid, never by pattern.
APP_PID=
start_app() {
  as_ana "cd '$REPO_DEFAULT' && exec node app/server.js" >"${1:-/dev/null}" 2>&1 &
  APP_PID=$!
  for _ in $(seq 50); do
    curl -s -o /dev/null http://localhost:3000/api/products && return 0
    sleep 0.1
  done
  echo "start_app: the app did not answer" >&2
  return 1
}
stop_app() {
  [ -n "$APP_PID" ] || return 0
  pkill -P "$APP_PID" 2>/dev/null
  kill "$APP_PID" 2>/dev/null
  wait "$APP_PID" 2>/dev/null
  APP_PID=
}

# One capture at a time: they share the project directory and port 3000.
lock() {
  exec 9>/tmp/web-automation-lab.lock
  flock 9
}

# The machine itself: ana, her ~/bin and the browsers where the tools look.
machine() {
  id ana >/dev/null 2>&1 || useradd -M -d "$ANA_HOME" -s /bin/bash ana
  mkdir -p "$ANA_HOME/bin" "$ANA_HOME/.cache/ms-playwright"
  local b
  for b in chromium-1194 chromium_headless_shell-1194 ffmpeg-1011; do
    [ -d "$ANA_HOME/.cache/ms-playwright/$b" ] || cp -a "/opt/pw-browsers/$b" "$ANA_HOME/.cache/ms-playwright/"
  done
  ln -sf "$ANA_HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome" "$ANA_HOME/bin/google-chrome"
  if [ ! -x "$ANA_HOME/bin/chromedriver" ]; then
    local tmp
    tmp=$(mktemp -d)
    pip download --quiet --no-deps -d "$tmp" 'chromedriver-py==141.0.7390.122' &&
      python3 -m zipfile -e "$tmp"/chromedriver_py-*.whl "$tmp/x" &&
      install -m 755 "$tmp/x/chromedriver_py/chromedriver_linux64" "$ANA_HOME/bin/chromedriver"
    rm -rf -- "$tmp"
  fi
  chown -R ana:ana "$ANA_HOME"
}

case ${1:-} in
  lib) ;;
  stage) machine && stage "$2" "${3:-}" ;;
  files) blocks "$2" ;;
  fence) fence "$2" "$3" ;;
  machine) machine ;;
  *) echo "usage: lab.sh stage N [DIR] | files N | fence SECTION.md PATH | machine | lib" >&2; exit 2 ;;
esac
