#!/usr/bin/env bash
# The harness every transcript in this course was recorded with. IT IS THE
# AUTHOR'S, NOT THE STUDENT'S, AND IT HOLDS NONE OF THE LAB.
#
# The student builds each network with ~/netlab/netlab.sh and one file per
# network, ~/netlab/NAME.sh. Every one of those files is shown whole in a
# lesson: netlab.sh and office.sh in lesson 1, each other network in the first
# lesson that uses it. This harness copies them out of the lessons' Markdown,
# byte for byte, into $NETLAB, and runs those copies. So a capture runs exactly
# the file the student was shown, and the two cannot drift apart. A file shown
# in two places, or a network a capture asks for that no lesson shows, stops
# it.
#
# A fence is a lab file when it is a ```bash block whose first line is
# "# ~/netlab/NAME.sh". The English lessons are read; validate-content already
# holds every Portuguese fence to its English one.
#
#   sudo bash lab.sh up SCENARIO     build one network, as netlab.sh up does
#   sudo bash lab.sh down
#   sudo bash lab.sh exec HOST USER 'command'   one command on one device
#   sudo bash lab.sh rogue           lesson 10's second DHCP server (below)
#   sudo bash lab.sh list            the files the lessons show
#
# The machine: Ubuntu Server 24.04 in a virtual machine, kernel 6.8, made from
# Ubuntu's cloud image with a user called ana who may sudo without a password,
# hostname lab, TZ America/Sao_Paulo, and the packages lesson 1 installs.
set -euo pipefail

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NETLAB=${NETLAB:-/var/tmp/netlab}

extract() {
  rm -rf "$NETLAB"; mkdir -p "$NETLAB"
  python3 - "$COURSE" "$NETLAB" <<'PY'
import json, os, re, sys
course, out = sys.argv[1], sys.argv[2]
seen = {}
for le in json.load(open(os.path.join(course, "course.json")))["lessons"]:
    d = os.path.join(course, "lessons", le)
    for s in json.load(open(os.path.join(d, "lesson.json")))["sections"]:
        md = os.path.join(d, s["slug"] + ".md")
        if not os.path.exists(md):
            continue
        lines = open(md).read().split("\n")
        i = 0
        while i < len(lines):
            if lines[i] == "```bash" and i + 1 < len(lines):
                m = re.match(r"# ~/netlab/([a-z0-9-]+\.sh)\b", lines[i + 1])
                j = lines.index("```", i + 1)
                if m:
                    name = m.group(1)
                    if name in seen:
                        sys.exit(f"lab.sh: {name} is shown twice, in {seen[name]} and {md}")
                    seen[name] = md
                    open(os.path.join(out, name), "w").write("\n".join(lines[i + 1:j]) + "\n")
                i = j
            i += 1
if "netlab.sh" not in seen:
    sys.exit("lab.sh: no lesson shows ~/netlab/netlab.sh")
PY
}

# Lesson 10 shows what a second DHCP server on the office LAN does, and how the
# switch stops it. It never shows how to start one, so the student is not
# given this, and the lesson says the rogue block is to be read.
rogue() {
  bash "$NETLAB/netlab.sh" on rogue root 'ip addr add 10.20.10.66/24 dev eth0'
  cat > /run/lab/rogue/dhcpd.conf <<'CONF'
default-lease-time 600;
subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.200 10.20.10.220;
  option routers 10.20.10.66;
  option domain-name-servers 10.20.10.66;
}
CONF
  touch /run/lab/rogue/dhcp/dhcpd.leases
  ip netns exec rogue setsid unshare --mount sh -c \
    "mount --bind /run/lab/rogue/dhcp /var/lib/dhcp; exec dhcpd -4 -f -d -cf /run/lab/rogue/dhcpd.conf -pf /run/lab/rogue/dhcpd.pidfile eth0" \
    </dev/null >/run/lab/rogue/dhcpd.log 2>&1 &
  echo $! > /run/lab/rogue/dhcpd.pid
  echo /run/lab/rogue/dhcpd.pid >> /run/lab/pidfiles
}

case "${1:-}" in
  up)    extract; bash "$NETLAB/netlab.sh" up "${2:?which scenario? try: lab.sh list}" >/dev/null ;;
  down)  [ -f "$NETLAB/netlab.sh" ] || extract; bash "$NETLAB/netlab.sh" down ;;
  exec)  shift; bash "$NETLAB/netlab.sh" on "$@" ;;
  rogue) rogue ;;
  list)  extract; ls "$NETLAB" ;;
  *)     sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 2 ;;
esac
