#!/usr/bin/env bash
# boxoffice, the application every lesson of manual-testing tests.
#
# boxoffice is the ticket office of a small theatre in São Paulo: three shows,
# accounts confirmed by e-mail, orders that move from reserved to paid to used.
# It is one Python file with nothing outside the standard library, it keeps
# everything in memory, and stopping it and starting it again resets it. It
# carries known defects on purpose; the lessons find them one technique at a
# time, and the list is below so a reviewer can check each lesson against it.
#
#   bash lab.sh app DIR          write boxoffice.py 1.0 into DIR, from lesson 1
#   bash lab.sh release DIR      apply the 1.1 edits of lesson 9 to DIR/boxoffice.py
#   bash lab.sh serve DIR [VAR=value ...]
#                                start DIR/boxoffice.py in the background with
#                                those variables, and wait until it answers
#   bash lab.sh stop             stop it
#   bash lab.sh isolated CMD...  run CMD in a network namespace of its own, with
#                                only a loopback, so two captures on port 8000
#                                never meet
#   source lab.sh lib            the helpers a captures.sh uses: run, block, say
#
# THE STUDENT NEVER SEES THIS FILE (C-40). boxoffice.py is shown whole in
# lesson 1 section `the-app`, under the sentence "Save it as `boxoffice.py`",
# and `app` EXTRACTS it from there rather than keeping a copy, so the file the
# captures run is the file the lesson shows, byte for byte. The 1.1 release is
# the same: lesson 9 section `release-1-1` shows each edit as a pair of python
# fences, the lines to find and the lines to put in their place, and `release`
# applies exactly those pairs.
#
# THE KNOWN DEFECTS OF 1.0, and the lesson that finds each:
#   1. six tickets are refused although the rule says 1 to 6     (lesson 4)
#   2. a quantity that is not a number answers 500 and a Python
#      traceback                                                 (lesson 4)
#   3. a member booking five or more gets 25% off, not the larger
#      of 10% and 15%                                            (lesson 5)
#   4. a used order can be refunded, and its seats come back      (lesson 5)
#   5. "cannot be payed", "cannot be useed": the message glues
#      "ed" onto the action                                      (lesson 11)
#   6. a refund is accepted after the show has started            (lesson 11)
#   7. the table of shows is 760 pixels wide, so a phone scrolls
#      sideways                                                  (lesson 7)
#   8. the tickets field has a placeholder and no label           (lesson 14)
#   9. booking closes by the machine's own time zone, so on a
#      machine set to UTC it closes three hours early            (lesson 21)
#  10. asking for a new confirmation link leaves the old one
#      working                                                   (lesson 22)
# And 1.1 (lesson 9) fixes 1 and 3 and breaks the student discount, which
# lesson 10's regression run finds.
#
# CAPTURES ARE STAGED IN THREE WAYS, and each captures.sh says which it uses:
# the server is started by this script with BOXOFFICE_NOW and BOXOFFICE_SEED
# set, so dates and tokens are the same on every run (the lessons say the
# student's will differ); TZ is America/Sao_Paulo unless a capture says
# otherwise; and HOME is /home/ana, so the prompt reads as Ana's.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1=$HERE/lessons/le-tnnchm7w/the-app.md
L9=$HERE/lessons/le-t3grs6r3/release-1-1.md
PIDFILE=${BOXOFFICE_PIDFILE:-/tmp/boxoffice-lab-$(readlink /proc/self/ns/net | tr -dc 0-9).pid}
NOW_DEFAULT=2026-10-10T14:00:00-03:00

# The fences of a Markdown file, in order, as files fence-1, fence-2… in $2,
# each with the label of its fence in fence-N.label.
fences() {
  python3 - "$1" "$2" <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
out = pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
for n, m in enumerate(re.finditer(r"^```([^\n]*)\n(.*?)^```$", text, re.S | re.M), 1):
    (out / f"fence-{n}").write_text(m.group(2))
    (out / f"fence-{n}.label").write_text(m.group(1))
PY
}

app() {
  local dir=$1
  mkdir -p "$dir"
  python3 - "$L1" "$dir/boxoffice.py" <<'PY' || { echo "lab: no boxoffice.py in lesson 1" >&2; return 1; }
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r"Save it as `boxoffice\.py`[^\n]*\n+```python\n(.*?)^```$", text, re.S | re.M)
if not m:
    sys.exit(1)
pathlib.Path(sys.argv[2]).write_text(m.group(1))
PY
}

release() {
  local dir=$1
  python3 - "$L9" "$dir/boxoffice.py" <<'PY' || { echo "lab: the 1.1 edits did not apply" >&2; return 1; }
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
blocks = re.findall(r"^```python\n(.*?)^```$", text, re.S | re.M)
if not blocks or len(blocks) % 2:
    sys.exit("an odd number of python fences: every edit is a pair")
target = pathlib.Path(sys.argv[2]); code = target.read_text()
for old, new in zip(blocks[::2], blocks[1::2]):
    if code.count(old) != 1:
        sys.exit("an edit whose old lines are not in the file exactly once:\n" + old)
    code = code.replace(old, new)
target.write_text(code)
PY
}

serve() {
  local dir=$1; shift
  stop >/dev/null 2>&1
  ( cd "$dir" && exec env BOXOFFICE_NOW=$NOW_DEFAULT BOXOFFICE_SEED=lab \
      TZ=${TZ:-America/Sao_Paulo} "$@" python3 boxoffice.py ) </dev/null >"$dir/server.log" 2>&1 &
  echo $! >"$PIDFILE"
  local port=8000 kv
  for kv in "$@"; do case $kv in BOXOFFICE_PORT=*) port=${kv#*=};; esac; done
  for _ in $(seq 50); do
    curl -sf "http://127.0.0.1:$port/health" >/dev/null && return 0
    sleep 0.1
  done
  echo "lab: boxoffice did not answer on $port" >&2; cat "$dir/server.log" >&2; return 1
}

stop() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
  rm -f "$PIDFILE"; sleep 0.2
}

isolated() {
  unshare -n python3 - "$@" <<'PY'
import fcntl, socket, struct, subprocess, sys
s = socket.socket()
req = struct.pack("16sH14s", b"lo", 0, b"")
flags = struct.unpack("16sH14s", fcntl.ioctl(s, 0x8913, req))[1]
fcntl.ioctl(s, 0x8914, struct.pack("16sH14s", b"lo", flags | 1, b""))
sys.exit(subprocess.call(sys.argv[1:]))
PY
}

lib() {
  export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
  # block NAME: the line every block of a capture's output starts with
  block() { printf '##### %s\n' "$1"; }
  # run CMD: print it after Ana's prompt in the current directory, then run it
  # in a terminal of its own, so a program that behaves differently when its
  # output is not a terminal (curl's progress meter) prints what Ana sees
  run() {
    local where=${PWD/#$HOME/\~}
    printf 'ana@laptop:%s$ %s\n' "$where" "$*"
    script -qec "$*" /dev/null </dev/null | tr -d '\r'
  }
  trap 'stop >/dev/null 2>&1' EXIT
}

case ${1:-} in
  app|release|serve|stop|isolated) cmd=$1; shift; "$cmd" "$@" ;;
  lib) lib ;;
  *) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; [ "${BASH_SOURCE[0]}" = "$0" ] && exit 2 ;;
esac
