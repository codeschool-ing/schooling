#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson starts all seven machines
# and works from admin, which reaches every other one over SSH with the key
# hostlab.sh made. ana@admin is ana on admin.
#
# What is STAGED rather than typed: the four files on admin (hosts.csv,
# baseline.json and two Python programs) are written from this lesson's own
# Markdown, as the student writes them by pasting.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab up dns desk trap >/dev/null 2>&1

python3 - "$here" /tmp/l18-files <<'PY'
import json, os, re, sys
here, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for md in ("finding-machines.md", "software-inventory.md", "baseline-and-drift.md"):
    t = open(os.path.join(here, md)).read()
    for b in re.findall(r"^```schooling-example\n(.*?)\n```$", t, re.S | re.M):
        ex = json.loads(b)
        open(os.path.join(out, ex["file"]), "w").write("\n".join(p["code"] for p in ex["parts"]) + "\n")
    m = re.search(r"^```json\n(.*?)\n```$", t, re.S | re.M)
    if m:
        open(os.path.join(out, "baseline.json"), "w").write(m.group(1) + "\n")
    m = re.search(r"^```\n(name,address.*?)\n```$", t, re.S | re.M)
    if m:
        open(os.path.join(out, "hosts.csv"), "w").write(m.group(1) + "\n")
PY
lab up >/dev/null 2>&1
for f in hosts.csv baseline.json inventory.py drift.py; do
  lab exec admin ana "cat > $f" < /tmp/l18-files/$f
done

block sweep
on admin 'nmap -sn 192.168.60.0/24 | grep -E "report|done"'

block unlisted
on admin 'nmap -sn -oG - 192.168.60.0/24 | awk "/Up\$/{print \$2}" | sort > found.txt; cut -d, -f2 hosts.csv | tail -n +2 | sort > listed.txt; comm -23 found.txt listed.txt'

block collect
on admin 'python3 inventory.py web desk admin jump dns sw trap printer'

block drift
on admin 'python3 drift.py'

block fix
on web 'sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd >/dev/null 2>&1; echo done'
on admin 'python3 inventory.py web desk admin jump dns sw trap > /dev/null; python3 drift.py'
