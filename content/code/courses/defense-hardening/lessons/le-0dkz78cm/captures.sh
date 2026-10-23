#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash ../../lab.sh build                      # once: the images
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by hostlab.sh from
# lesson 1 (../../lab.sh extracts it from that lesson and runs it). A line that
# starts with ana@web ran on the machine called web, as ana; ana@admin on admin.
#
# What is STAGED rather than typed: the lab itself, `up web admin`, fresh, so
# web is the portal as it was handed over, with every weakness lesson 1 found.
# The two files the student writes, check.sh and harden.yml, are not typed by
# this script: they are extracted from this lesson's own Markdown (the
# schooling-example blocks) and copied in, so the file a transcript runs is
# the file the lesson shows.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100 ANSIBLE_NOCOLOR=1
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
files=$(mktemp -d)
python3 - "$here" "$files" <<'PY'
import glob, json, os, re, sys
here, out = sys.argv[1], sys.argv[2]
for md in sorted(glob.glob(os.path.join(here, "*.md"))):
    if md.endswith(".pt.md"):
        continue
    for block in re.findall(r"^```schooling-example\n(.*?)\n```$", open(md).read(), re.S | re.M):
        ex = json.loads(block)
        if ex.get("file"):
            open(os.path.join(out, ex["file"]), "w").write("\n".join(p["code"] for p in ex["parts"]) + "\n")
PY
put() { lab exec "$1" ana "cat > $2" < "$files/$2"; }   # put HOST FILE: the lesson's file, in ana's home

lab up web admin >/dev/null 2>&1

block lynis
on web 'sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt'

block lynis-warnings
on web "sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2"

block lynis-suggestions
on web "sudo grep -c '^suggestion' /var/log/lynis-report.dat"
on web "sudo grep -E '^suggestion.*(AUTH|BANN|KRNL-5820|FILE-6310)' /var/log/lynis-report.dat | cut -d'|' -f1,2"

block lynis-details
on web 'sudo lynis show details AUTH-9204 | head -8'

block scap-profiles
on web 'ls /usr/share/xml/scap/ssg/content/ | grep ds.xml'
on web 'oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml'

block scap-eval
on web 'sudo oscap xccdf eval --profile cis_level1_server /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | grep ^Result | sort | uniq -c'

block scap-why
on web "grep -o 'cpe:/o:canonical:ubuntu_linux:[0-9.]*' /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | sort -u"
on web 'grep VERSION_ID /etc/os-release'

put web check.sh
block check-before
on web 'sudo bash check.sh; echo "failed: $?"'

block inventory
on admin 'printf "[portal]\nweb\n" > hosts.ini; ansible -i hosts.ini portal -m ping'

put admin harden.yml
block playbook
on admin 'ansible-playbook -i hosts.ini harden.yml'

block again
on admin 'ansible-playbook -i hosts.ini harden.yml | tail -2'

block check-after
on web 'sudo bash check.sh; echo "failed: $?"'

block lynis-after
on web 'sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt'
on web "sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2"

block drift
on web 'echo "PermitRootLogin yes" | sudo tee /etc/ssh/sshd_config.d/05-quickfix.conf'
on web 'sudo bash check.sh | grep FAIL; echo "failed: ${PIPESTATUS[0]}"'
on admin 'ansible-playbook -i hosts.ini harden.yml | tail -2'

block drift-fix
on web 'sudo rm /etc/ssh/sshd_config.d/05-quickfix.conf && sudo systemctl reload ssh && sudo bash check.sh | grep -c PASS'

block exception
on web 'printf "skip-test=FILE-6310\n" | sudo tee /etc/lynis/custom.prf'
on web 'sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed|Skipped" lynis.txt; grep -c FILE-6310 lynis.txt'

rm -rf "$files"
