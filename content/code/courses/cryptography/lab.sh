#!/usr/bin/env bash
# The machine every transcript in cryptography was recorded on, built the way
# the lessons teach a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE, and does not need to. Lesson 1, section
# `the-lab`, installs the packages, makes ~/lab and its Python, and writes
# `vcrypt`, a five-line command that runs ~/lab/tools/NAME.py. Every tool in
# ~/lab/tools is shown whole in the lesson that first uses it, as a fence
# whose first line (second, after a #!) is its path:
#
#   # ~/lab/tools/seal.py
#
# and every file in ~/lab/keys and ~/lab/data is made by commands a lesson
# shows, in a fence of `sh` whose first line is `cd ~/lab` (or, in lesson 1,
# the `mkdir -p ~/lab/...` that makes it). This script does not keep a copy of either. It
# reads the tools out of the lessons' fences and runs the lessons' own `sh`
# fences, from the sections listed in STEPS below, in course order, so that
# the program the course ran is the program the student typed.
#
# What it adds, and a person does not need: the user `ana` the transcripts
# print (`ana@lab`); /home/ana as HOME unless LAB_HOME says otherwise; the
# stock Python 3.12 of Ubuntu 24.04 as `python3`, because the recording
# machine had a 3.13 beside it; and it skips `sudo apt-get`, because the
# recording machine already has the packages and a capture must not depend on
# the network for them. The pip install in lesson 1 does use the network.
#
# THE STORY. Vereda Fisioterapia is a small chain of physiotherapy clinics in
# Sao Paulo, with a patient portal at portal.vereda.example. Vereda is
# invented, and so is every name, record and password in ~/lab.
#
# WHAT IS FIXED ON PURPOSE, AND WHY IT WOULD BE A DEFECT ANYWHERE ELSE
#
#   - EVERY KEY IS DERIVED FROM A PUBLIC LABEL (tools/drbg.py, in lesson 1),
#     so that the student's keys are the lesson's and the transcripts repeat
#     byte for byte. The lessons say so, and lesson 17 says why a key anybody
#     can rebuild is no key.
#   - The IVs and nonces the commands pass are written in the commands.
#   - The lab's present is 2026-06-15 12:00 in Sao Paulo (epoch 1781535600).
#     Certificates carry fixed dates and every check passes that instant with
#     -attime, so "expired" means the same thing whenever a capture is run.
#
#   bash lab.sh reset            rebuild ~/lab from nothing, as lessons 1 to 17
#                                build it, without their servers
#   bash lab.sh steps LESSON SECTION
#                                run the `sh` fences of one section: how a
#                                lesson's captures.sh starts the servers that
#                                lesson asks the student to start
#   bash lab.sh files            print every tool path the lessons define
#
# It needs, beyond what the lessons install: python3.12, and root for the
# lessons that start servers.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export HOME=${LAB_HOME:-/home/ana}
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
export PIP_CACHE_DIR=/var/cache/cryptography-pip   # not ana's home: root runs this

# The sections whose `sh` fences build ~/lab, in course order. A section that
# starts a server is not here: its lesson's captures.sh runs it.
STEPS="
le-m9cj97me the-lab
le-cjcdfccn two-keys
"

STOCK=/usr/local/lib/cryptography-stock
mkdir -p $STOCK && ln -sfn /usr/bin/python3.12 $STOCK/python3

# fences.py MODE ...: the one parser of the lessons' fences.
fences() {
  python3.12 - "$here" "$@" <<'PY'
import json, os, re, sys

here, mode, *rest = sys.argv[1:]
course = json.load(open(os.path.join(here, "course.json")))
FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```$", re.S | re.M)
PATH = re.compile(r"^# (~/lab/\S+)$")

def sections():
    for lesson in course["lessons"]:
        d = os.path.join(here, "lessons", lesson)
        for s in json.load(open(os.path.join(d, "lesson.json")))["sections"]:
            p = os.path.join(d, s["slug"] + ".md")
            if os.path.exists(p):
                yield lesson, s["slug"], open(p, encoding="utf-8").read()

if mode in ("files", "write"):
    seen = {}
    for lesson, slug, text in sections():
        for m in FENCE.finditer(text):
            lines = m.group(2).split("\n")
            for line in lines[:2]:
                pm = PATH.match(line)
                if pm:
                    path = pm.group(1)
                    if path in seen:
                        sys.exit(f"{path} is defined twice: {seen[path]} and {lesson}/{slug}")
                    seen[path] = f"{lesson}/{slug}"
                    if mode == "files":
                        print(f"{path}  {lesson}/{slug}")
                    else:
                        dest = os.path.join(os.environ["HOME"], path[2:])
                        os.makedirs(os.path.dirname(dest), exist_ok=True)
                        open(dest, "w", encoding="utf-8").write(m.group(2))
                    break
elif mode == "steps":
    lesson, slug = rest
    found = [t for l, s, t in sections() if (l, s) == (lesson, slug)]
    if not found:
        sys.exit(f"no section {lesson}/{slug}")
    # A step is an `sh` fence that starts in the lab: its first line is
    # `cd ~/lab` or makes it. Any other `sh` fence in the section is an
    # illustration (`openssl genpkey` in lesson 2) and is not run.
    blocks = [m.group(2) for m in FENCE.finditer(found[0]) if m.group(1) == "sh"
              and re.match(r"(cd|mkdir -p) ~/lab\b", m.group(2))]
    if not blocks:
        sys.exit(f"{lesson}/{slug} has no sh fence that starts in ~/lab")
    for b in blocks:
        sys.stdout.write("".join(l + "\n" for l in b.split("\n")
                                 if l and not l.startswith("sudo apt-get ")))
PY
}

steps() {
  # As the student types them: in a login shell's PATH, from their home.
  local script
  script=$(fences steps "$1" "$2")
  (cd "$HOME" && PATH=$STOCK:$HOME/lab/bin:$PATH bash -euo pipefail -c "$script")
}

reset() {
  id ana >/dev/null 2>&1 || { useradd -m -s /bin/bash ana; usermod -p '*' ana; }
  mkdir -p "$HOME"
  rm -rf "$HOME/lab"
  cp /etc/skel/.bashrc "$HOME/.bashrc"
  fences write
  local lesson section
  while read -r lesson section; do
    [ -n "$lesson" ] && steps "$lesson" "$section"
  done <<< "$STEPS"
  return 0
}

case "${1:-}" in
  reset) reset ;;
  steps) steps "$2" "$3" ;;
  files) fences files ;;
  *) echo "usage: bash lab.sh reset | steps LESSON SECTION | files" >&2; exit 2 ;;
esac
