#!/usr/bin/env bash
# The network every transcript in this course was recorded on, and how the
# author's copy of it is kept identical to the student's.
#
# THE STUDENT NEVER RECEIVES THIS FILE. What they build is netlab.sh, which
# lesson 1 shows whole in its section "Building the network", and tunnel.py,
# which the same lesson shows whole in "IP-in-IP". This script does not carry
# a copy of either: it EXTRACTS both from the lesson's Markdown, joining the
# parts of each schooling-example exactly as the page's copy button does, and
# installs them where the lesson tells the student to put them. So the program
# the captures run is the program the page hands over, byte for byte, and the
# two cannot drift apart.
#
#   sudo bash lab.sh install                 extract and install, then stop
#   sudo bash lab.sh up|down|reset           install, then netlab.sh VERB
#   sudo bash lab.sh exec|kill|span|shell …  netlab.sh VERB … (installed copy)
#
# Run it with sudo from the account the captures are recorded as (ana): that
# account's home gets netlab.sh, as the student's does.
#
# WHAT THE KERNEL COULD NOT DO, AND WHAT STANDS IN FOR IT. The kernel the
# course was recorded on was built without GRE, IP-in-IP, WireGuard, ESP and
# netem, and so are the kernels of some online environments. So:
#   - GRE and IP-in-IP are tunnel.py, a user-space tunnel over a TUN device.
#   - WireGuard is wireguard-go; wg-quick falls back to it by itself.
#   - IPsec is strongSwan with kernel-libipsec, which netlab.sh switches on.
#   - There is no added delay on any link, and the prose says so.
# On a student's Ubuntu 24.04 the kernel has all of them; the lessons say
# where that changes a line of output.
#
# Recorded on Ubuntu 24.04.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1="$HERE/lessons/le-8bk5bjzb"
ME=${SUDO_USER:?run it with sudo from the account the captures are recorded as}
NETLAB="/home/$ME/netlab.sh"

# extract FILE.md NAME: the schooling-example whose "file" is NAME, as the copy
# button hands it over.
extract() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
md, name = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
for body in re.findall(r"^```schooling-example\n(.*?)\n```$", md, re.S | re.M):
    ex = json.loads(body)
    if ex.get("file") == name:
        sys.stdout.write("\n".join(p["code"] for p in ex["parts"]) + "\n")
        sys.exit(0)
sys.exit(f"{sys.argv[1]}: no schooling-example for {name}")
PY
}

install_files() {
  extract "$L1/building-the-network.md" netlab.sh > "$NETLAB.new"
  mv "$NETLAB.new" "$NETLAB"; chown "$ME:" "$NETLAB"
  extract "$L1/ip-in-ip.md" tunnel.py > /usr/local/bin/tunnel.py.new
  install -m 755 /usr/local/bin/tunnel.py.new /usr/local/bin/tunnel.py
  rm -f /usr/local/bin/tunnel.py.new
}

case "${1:-}" in
  install) install_files ;;
  up|down|reset) install_files; exec bash "$NETLAB" "$1" ;;
  *) exec bash "$NETLAB" "$@" ;;
esac
