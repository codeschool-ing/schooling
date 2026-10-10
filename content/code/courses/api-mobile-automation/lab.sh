#!/usr/bin/env bash
# The author's lab for api-mobile-automation: what proves every transcript in
# the course was run. THE STUDENT NEVER SEES THIS FILE (C-38, C-40), and no
# lesson names it. Everything the student needs is shown whole in a lesson.
#
#   bash lab.sh files N DIR   write into DIR every file lessons 1..N show whole
#   source lab.sh             in a lesson's captures.sh: the helpers below
#
# THE PROJECT COMES OUT OF THE LESSONS. A lesson that hands the student a file
# writes "save it as `PATH`:" on the line before its block. `files` reads the
# English prose of lessons 1..N in the order course.json gives them, and writes
# each such block to DIR/PATH, a later lesson's version replacing an earlier
# one. So a capture runs the very bytes the lesson prints, and the two cannot
# drift apart.
#
# THE MACHINE IS THIS SANDBOX, AS ANA. It runs Ubuntu 24.04, which is what
# lesson 1 recommends. Lesson 1's setup was done on it with the commands that
# lesson prints (apt-get for curl, jq, a JDK and Maven; Node 22.22.0 from
# nodejs.org into /opt/node), and every command runs as a user `ana` whose
# home is /home/ana, with a clean environment: PATH is /opt/node/bin and the
# system's directories, TZ is America/Sao_Paulo, LANG is C.UTF-8. The prompt is
# printed as `ana@laptop`, the machine the lessons call the student's.
#
# What is STAGED, and every lesson's captures.sh header repeats what it uses:
#   - the network. This sandbox reaches the internet through a proxy, so the
#     environment carries HTTPS_PROXY for npm and curl, and ana's
#     ~/.m2/settings.xml names the same proxy for Maven. A student's machine
#     needs neither. Nothing the
#     lessons show talks to anything but localhost once a package is installed;
#   - colour. Maven and a few npm tools colour their output; the escape codes
#     are removed from what is printed, which is what the reader sees as text;
#   - one capture at a time. Every lesson starts boxoffice on port 8080, so a
#     lock serialises the captures.
set -uo pipefail
LAB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

lab_files() { # N DIR
  python3 - "$LAB_DIR" "$1" "$2" <<'PY'
import json, os, re, sys
course, n, dest = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lessons = json.load(open(os.path.join(course, "course.json")))["lessons"][:n]
said = re.compile(r"[Ss]ave it as `([^`]+)`:\s*$")
for lid in lessons:
    d = os.path.join(course, "lessons", lid)
    spec = json.load(open(os.path.join(d, "lesson.json")))
    for sec in spec["sections"]:
        md = os.path.join(d, sec["slug"] + ".md")
        if not os.path.exists(md):
            continue
        lines = open(md).read().split("\n")
        i = 0
        while i < len(lines):
            m = said.search(lines[i])
            if m:
                j = i + 1
                while j < len(lines) and not lines[j].startswith("```"):
                    j += 1
                ticks = re.match(r"`+", lines[j]).group(0)
                k = j + 1
                while not lines[k].startswith(ticks) or lines[k].strip("`").strip():
                    k += 1
                path = os.path.join(dest, m.group(1))
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w") as f:
                    f.write("\n".join(lines[j + 1:k]) + "\n")
                i = k
            i += 1
PY
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    files) lab_files "$2" "$3"; exit $? ;;
    *) sed -n '2,12p' "$0"; exit 2 ;;
  esac
fi

# ---- the helpers a captures.sh sources -----------------------------------
# LAB_EXTRA holds variables a lesson has the student set, such as TOKEN=…, so a
# command can be printed exactly as typed and still find them.
LAB_HOME=/home/ana
LAB_CWD=$LAB_HOME
LAB_PROXY=${HTTPS_PROXY:-}
exec 9>/tmp/api-mobile-automation.lock
flock 9

# Maven reads its proxy from settings.xml and nowhere else, so ana's is
# rewritten with the port this sandbox's proxy has today.
mkdir -p $LAB_HOME/.m2
printf '<settings><proxies><proxy><id>sandbox</id><active>true</active><protocol>https</protocol><host>127.0.0.1</host><port>%s</port><nonProxyHosts>localhost|127.0.0.1</nonProxyHosts></proxy></proxies></settings>\n' \
  "${LAB_PROXY##*:}" > $LAB_HOME/.m2/settings.xml
chown -R ana:ana $LAB_HOME/.m2

block() { printf '##### %s\n' "$1"; }

# The prompt, with ~ for the home directory, as bash would print it.
prompt() { printf 'ana@laptop:%s$ ' "${LAB_CWD/#$LAB_HOME/\~}"; }

as_ana() {
  runuser -u ana -- env -i HOME=$LAB_HOME USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=/opt/node/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 TZ=America/Sao_Paulo TERM=dumb NO_COLOR=1 ${LAB_EXTRA:-} \
    HTTPS_PROXY="$LAB_PROXY" https_proxy="$LAB_PROXY" NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 \
    bash -c "cd \"$LAB_CWD\" && { $1
}"
}

strip() { sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/\r$//'; }

# run CMD: print the prompt and the command, then what it printed. It runs on
# a pseudo-terminal, as it would in the student's, so a program that behaves
# differently when its output is a pipe (curl's progress meter) does not.
run() { prompt; printf '%s\n' "$1"; as_ana "script -qec $(printf '%q' "$1") /dev/null" 2>&1 | strip; }

# quiet CMD: run it without showing it, for setting the stage.
quiet() { as_ana "$1" >/dev/null 2>&1; }

# go DIR: change directory, shown as the student would type it.
go() { prompt; printf 'cd %s\n' "$1"; LAB_CWD=$(as_ana "cd $1 && pwd"); }

# here DIR: change directory without showing it.
here() { LAB_CWD=$1; }

# serve NAME CMD: start a server in the background, its output in /tmp/NAME.log.
serve() {
  as_ana "$2 > /tmp/lab-$1.log 2>&1 < /dev/null 9>&- & echo \$! > /tmp/lab-$1.pid"
  for _ in $(seq 50); do
    grep -q listening "/tmp/lab-$1.log" 2>/dev/null && return 0
    sleep 0.1
  done
  echo "lab: $1 did not start" >&2; cat "/tmp/lab-$1.log" >&2; return 1
}

# halt NAME: stop what serve started, by its pid and never by a pattern.
halt() {
  [ -f "/tmp/lab-$1.pid" ] || return 0
  kill "$(cat "/tmp/lab-$1.pid")" 2>/dev/null
  rm -f "/tmp/lab-$1.pid"
  sleep 0.3
}

# project N DIR: the student's project as lessons 1..N leave it, owned by ana.
project() {
  rm -rf "$2"; mkdir -p "$2"
  lab_files "$1" "$2" || exit 1
  chown -R ana:ana "$2"
}
