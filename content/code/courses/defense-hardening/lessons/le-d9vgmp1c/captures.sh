#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson uses web (whose packages are
# assessed) and admin (where the scripts run). ana@admin is ana on admin.
#
# What is STAGED rather than typed: the four files on admin (feed.json and three
# Python programs) are written from this lesson's own Markdown, as the student
# writes them by pasting. The advisory feed is invented for the lesson; its
# fixed versions are chosen against the versions Ubuntu's archive had on the day
# of the capture, so a later run may move a line between VULNERABLE and fixed.
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

# The three programs and the feed are taken from this lesson's own sections, byte for
# byte as the copy button hands them over, and written on admin as ana.
python3 - "$here" /tmp/l16-files <<'PY'
import json, os, re, sys
here, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for md in ("installed-versus-fixed.md", "cvss.md", "prioritising.md"):
    t = open(os.path.join(here, md)).read()
    for b in re.findall(r"^```schooling-example\n(.*?)\n```$", t, re.S | re.M):
        ex = json.loads(b)
        open(os.path.join(out, ex["file"]), "w").write("\n".join(p["code"] for p in ex["parts"]) + "\n")
    m = re.search(r"^```json\n(.*?)\n```$", t, re.S | re.M)
    if m:
        open(os.path.join(out, "feed.json"), "w").write(m.group(1) + "\n")
PY
lab up web admin >/dev/null 2>&1
for f in feed.json vulncheck.py cvss.py prioritise.py; do
  lab exec admin ana "cat > $f" < /tmp/l16-files/$f
done

block versions
on web "dpkg-query -W -f='\${Package} \${Version}\n' openssh-server nginx sudo curl"

block vulncheck
on admin 'ls'
on admin 'python3 vulncheck.py feed.json web'

block scan
on admin 'nmap -sV -p 22,80 web | grep -E "^(PORT|[0-9])"'

block cvss
on admin 'python3 cvss.py AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H $(jq -r ".[].cvss" feed.json)'

block prio
on admin 'python3 vulncheck.py feed.json web | python3 prioritise.py feed.json 2026-10-23'

block verify
on web 'sudo apt-get purge -y -q vsftpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2'
on admin 'python3 vulncheck.py feed.json web | grep vsftpd'

block dates
on admin 'for d in 7 30 60 90; do date -d "2026-10-23 + $d days" +"%F  $d days"; done'
