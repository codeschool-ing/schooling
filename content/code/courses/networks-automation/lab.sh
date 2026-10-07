#!/usr/bin/env bash
# The author's harness for this course's transcripts. The student never sees it:
# they build the same lab from the lessons, and so does this file.
#
# EVERYTHING THE LAB RUNS IS READ OUT OF THE LESSONS. The student's build script,
# netlab.sh, is printed whole in lesson 1; the programs it starts are printed
# whole in the lessons that introduce them (devapid.py in 2, lab_restconf.c in
# 3, deskd.py in 7, napalm_frr.py in 8, netbox_seed.py in 12); and the commands
# that install the software are the `sh` fences of the sections named in TOOLS.
# This file extracts them and runs them, so a transcript can only have come
# from what the student is given. Nothing here is a second copy of any of it.
#
#   sudo bash lab.sh tools               once: run the install sections, as ubuntu
#   sudo bash lab.sh reset               the lab as every lesson starts it
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'
#   sudo bash lab.sh host 'command'      on the VM itself, as ubuntu@netlab
#   bash lab.sh check                    every file a captures.sh writes is in a lesson
#
# The student types these as the user ubuntu, on a machine called netlab, which
# is what Multipass gives them; the files go in ~ubuntu/netlab. Recorded on
# Ubuntu 24.04 in a cloud VM whose python3 was 3.13 and which had no systemd:
# `tools` points python3 back at Ubuntu's 3.12 first, gives /etc/hosts the
# name netlab as a VM's has, and skips the one fence
# that only means something with systemd (it says so when it does).
set -euo pipefail

COURSE=$(cd "$(dirname "$0")" && pwd)
L=$COURSE/lessons
STUDENT=/home/ubuntu
NETLAB=$STUDENT/netlab

# FILE  LESSON SECTION: where each file the student saves is printed.
FILES="
netlab.sh       le-q3ch6vgt building-it.md
devapid.py      le-0ef07bmx the-server.md
lab_restconf.c  le-qrnak88r building-nc1.md
deskd.py        le-h33qkm0s the-desk.md
napalm_frr.py   le-tnv4a4sc a-driver.md
netbox_seed.py  le-d5xxv7je installing-netbox.md
"
# The sections whose `sh` fences install software, in the order a student meets them.
TOOLS="
le-q3ch6vgt your-lab.md
le-qrnak88r building-nc1.md
le-ckec2stb polling-and-streaming.md
le-6hhc1jz9 model-and-data.md
le-d5xxv7je installing-netbox.md
"

# shown MD NAME: the one fence whose preceding line names `~/netlab/NAME` and ends with a colon.
shown() {
  python3 - "$1" "$2" <<'PY'
import re, sys
md, name = sys.argv[1], sys.argv[2]
text = open(md, encoding="utf-8").read()
found = re.findall(r"^[^\n]*`~/netlab/" + re.escape(name) + r"`[^\n]*:\n\n```[a-z]*\n(.*?)^```$", text, re.S | re.M)
if len(found) != 1:
    sys.exit(f"{md}: {len(found)} fences printing ~/netlab/{name}, and this needs exactly one")
sys.stdout.write(found[0])
PY
}

# fences MD: every `sh` fence in the section, in order, separated by a NUL.
fences() {
  python3 - "$1" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
for f in re.findall(r"^```sh\n(.*?)^```$", text, re.S | re.M):
    sys.stdout.write(f + "\0")
PY
}

host() {  # host 'command': as the student types it on the VM
  unshare --uts bash -c 'hostname netlab; cd '"$STUDENT"'; exec runuser -u ubuntu -- env -i HOME='"$STUDENT"' USER=ubuntu LOGNAME=ubuntu PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ=America/Sao_Paulo LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $1"' _ "$1"
}

files() {
  install -d -o ubuntu -g ubuntu "$NETLAB"
  local name lesson md
  while read -r name lesson md; do
    [ -n "$name" ] || continue
    shown "$L/$lesson/$md" "$name" > "$NETLAB/$name.new"
    mv "$NETLAB/$name.new" "$NETLAB/$name"
    chown ubuntu:ubuntu "$NETLAB/$name"
  done <<< "$FILES"
  chmod 755 "$NETLAB/netlab.sh"
}

tools() {
  id ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu
  printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/ubuntu
  # A Multipass VM knows its own name; this machine is only called netlab inside host()
  grep -q ' netlab$' /etc/hosts || printf '127.0.1.1 netlab\n' >> /etc/hosts
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 >/dev/null
  update-alternatives --set python3 /usr/bin/python3.12
  files
  local lesson md f
  while read -r lesson md; do
    [ -n "$lesson" ] || continue
    while IFS= read -r -d '' f; do
      case $f in
        "sudo systemctl"*) echo "skipped, no systemd here: ${f%%$'\n'*}" >&2; continue ;;
        "sudo ~/netlab/netlab.sh"*) continue ;;    # the lab is built by reset, not here
      esac
      echo "== $lesson/$md: ${f%%$'\n'*}" >&2
      host "set -e; $f" </dev/null
    done < <(fences "$L/$lesson/$md")
  done <<< "$TOOLS"
}

# Every lesson starts from a fresh lab and from an empty home for ana, which is
# what each lesson's captures assume. A student's home survives a reset, and
# what they kept from the previous lesson does not change a transcript.
fresh_home() {
  if id ana >/dev/null 2>&1; then
    rm -rf /home/ana
    install -d -o ana -g ana -m 750 /home/ana
    cp -a /etc/skel/. /home/ana/
    chown -R ana:ana /home/ana
  fi
}

# check: every file a lesson's captures.sh writes for ana (its `put` blocks) is
# printed in some lesson, line for line: in the lesson that writes it, or in
# the earlier one it is staged from. A file that exists only here is a file the
# student never receives.
check() {
  python3 - "$L" <<'PY'
import glob, json, re, sys
L = sys.argv[1]
shown = set()
for md in glob.glob(f"{L}/*/*.md"):
    if md.endswith(".pt.md"):
        continue
    t = open(md, encoding="utf-8").read()
    shown |= {x.rstrip() for x in t.splitlines()}
    for m in re.finditer(r"```schooling-example\n(.*?)\n```", t, re.S):
        for part in json.loads(m.group(1))["parts"]:
            shown |= {x.rstrip() for x in part["code"].splitlines()}
bad = 0
for cap in sorted(glob.glob(f"{L}/*/captures.sh")):
    for name, _, body in re.findall(r"^put (\S+) <<'(\w+)'\n(.*?)^\2$", open(cap).read(), re.S | re.M):
        missing = [x for x in body.splitlines() if x.strip() and x.rstrip() not in shown]
        if missing:
            bad += 1
            print(f"{cap}: {name}: {len(missing)} line(s) in no lesson, first: {missing[0]!r}")
sys.exit(1 if bad else 0)
PY
}

case ${1:-} in
  check) check ;;
  tools) tools ;;
  up)    files; "$NETLAB/netlab.sh" up ;;
  reset) files; "$NETLAB/netlab.sh" down; fresh_home; "$NETLAB/netlab.sh" up ;;
  down)  files; "$NETLAB/netlab.sh" down ;;
  exec)  "$NETLAB/netlab.sh" enter "$2" "$3" "$4" ;;
  host)  host "$2" ;;
  *) sed -n '2,24p' "$0"; exit 2 ;;
esac
