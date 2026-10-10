#!/usr/bin/env bash
# The author's harness for this course's transcripts. The student never sees
# it: they build the same machine from lesson 1, and so does this file.
#
# EVERYTHING THE LAB RUNS IS READ OUT OF THE LESSONS. The commands that install
# software are the `sh` fences of the sections named in TOOLS, run in order as
# the user ubuntu, the way the student types them. The programs the student
# saves in ~/work are the fences (or `schooling-example` blocks) that a lesson
# introduces with a line naming `~/work/NAME` and ending in a colon; `files`
# extracts every one of them. Nothing here is a second copy of any of it.
#
#   sudo bash lab.sh tools          once: a fresh ~ubuntu, then every install section
#   sudo bash lab.sh files          the student's programs, from the lessons, into ~/work
#   sudo bash lab.sh reset [1|3]    nothing running, a new cluster of N nodes, started
#   sudo bash lab.sh run 'command'  as ubuntu, in ~/work, in a login shell
#   bash lab.sh check               every ~/work file a captures.sh uses is in a lesson
#
# The student works in a Multipass virtual machine called `stream`, as the
# user `ubuntu`. This machine is a cloud container running Ubuntu 24.04 with
# no hypervisor and no systemd: `tools` gives it the hostname `stream` and
# the /etc/hosts line and the password-free sudo a VM has, and points python3 at Ubuntu's own 3.12 (the
# container had 3.13 as its default). Recorded with TZ=America/Sao_Paulo.
set -euo pipefail
exec 9>&-   # a capture holds a lock on fd 9; nothing started here may inherit it

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L=$COURSE/lessons
U=/home/ubuntu
export TZ=America/Sao_Paulo

# The sections whose `sh` fences install software, in the order a student meets them.
TOOLS="
le-pqqt0zyx your-lab.md
"

as_ubuntu() { runuser -u ubuntu -- env -i HOME=$U USER=ubuntu LOGNAME=ubuntu TERM=dumb TZ=$TZ LC_ALL=C.UTF-8 \
  bash -lc "$1"; }

# fences FILE: the bodies of the ```sh fences, in order, NUL-separated.
fences() {
  python3 - "$1" <<'PY'
import re, sys
for body in re.findall(r"^```sh\n(.*?)^```$", open(sys.argv[1], encoding="utf-8").read(), re.S | re.M):
    sys.stdout.write(body + "\0")
PY
}

# files: every program a lesson tells the student to save in ~/work.
files() {
  python3 - "$L" "$U/work" <<'PY'
import glob, json, os, re, sys
lessons, work = sys.argv[1], sys.argv[2]
os.makedirs(work, exist_ok=True)
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
seen = {}
for md in sorted(glob.glob(lessons + "/*/*.md")):
    if md.endswith(".pt.md"):
        continue
    for name, lang, body in pat.findall(open(md, encoding="utf-8").read()):
        if lang == "schooling-example":
            body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
        if name in seen:
            sys.exit(f"{md}: ~/work/{name} is printed twice (also in {seen[name]})")
        seen[name] = md
        with open(os.path.join(work, name), "w", encoding="utf-8") as f:
            f.write(body)
        if body.startswith("#!"):
            os.chmod(os.path.join(work, name), 0o755)
        print(f"{name:20} {os.path.relpath(md, lessons)}")
PY
  chown -R ubuntu:ubuntu "$U/work"
}

case "${1:-}" in
  tools)
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 >/dev/null
    update-alternatives --set python3 /usr/bin/python3.12
    hostname stream
    grep -q ' stream$' /etc/hosts || echo '127.0.1.1 stream' >> /etc/hosts
    # iproute2 (ss) is in every Ubuntu VM and was not in the container.
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q iproute2 >/dev/null
    # cloud-init gives a Multipass VM's ubuntu this line.
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-cloud-init-users
    # A fresh home, as a new virtual machine has.
    pkill -u ubuntu -f '^[^ ]*java ' || true
    rm -rf $U/kafka $U/venv $U/work $U/kafka-data $U/kafka_2.13-* $U/.cache
    cp /etc/skel/.profile $U/.profile && chown ubuntu:ubuntu $U/.profile
    for entry in $(echo "$TOOLS" | awk 'NF{print $1"/"$2}'); do
      while IFS= read -r -d '' body; do
        echo "== $entry"; as_ubuntu "cd ~ && set -e
$body"
      done < <(fences "$L/$entry")
    done ;;
  files) files ;;
  reset)
    n=${2:-1}
    pkill -u ubuntu -f '^[^ ]*python ' || true
    as_ubuntu "~/work/cluster.sh stop >/dev/null 2>&1 || true"
    pkill -9 -u ubuntu -f '^[^ ]*java ' || true
    as_ubuntu "~/work/cluster.sh new $n >/dev/null && ~/work/cluster.sh start >/dev/null" ;;
  run) as_ubuntu "cd ~/work && $2" ;;
  check)
    for c in "$L"/*/captures.sh; do grep -o '~/work/[A-Za-z0-9_.-]*' "$c" || true; done | sort -u ;;
  *) echo "usage: lab.sh tools | files | reset [1|3] | run 'command' | check" >&2; exit 2 ;;
esac
