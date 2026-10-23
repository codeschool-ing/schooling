#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of defense-hardening, as a script that produces them.
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
# starts with ana@admin ran on the machine called admin, as ana.
#
# What is STAGED rather than typed: the lab, `up admin web desk jump`, fresh.
# The four small files of the inventory (hosts.ini, group_vars/all.yml,
# group_vars/workstations.yml, host_vars/jump.yml) and the two systemd units
# are written by this script from the heredocs below; the lesson shows each of
# them whole, through the `head` and `cat` transcripts that print them back.
# baseline.yml is extracted from this lesson's Markdown (its schooling-example)
# so the playbook that ran is the one the lesson shows.
# Every line after a prompt is what the command printed. The Group Policy
# sections have no transcript: there is no Windows machine in the lab.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100 ANSIBLE_NOCOLOR=1
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {
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
write() { lab exec "$1" ana "mkdir -p \$(dirname $2) && cat > $2"; }   # write HOST PATH < content

lab up admin web desk jump >/dev/null 2>&1

write admin hosts.ini <<'EOF'
[servers]
web
jump

[workstations]
desk
EOF
write admin group_vars/all.yml <<'EOF'
ssh_max_auth_tries: 3
x11_forwarding: "no"
banner: "Jatoba Contabilidade. Authorised use only; sessions are logged."
EOF
write admin group_vars/workstations.yml <<'EOF'
x11_forwarding: "yes"
EOF
write admin host_vars/jump.yml <<'EOF'
ssh_max_auth_tries: 2
EOF
lab exec admin ana "cat > baseline.yml" < "$files/baseline.yml"

block inventory
on admin 'head -20 hosts.ini group_vars/*.yml host_vars/*.yml'

block graph
on admin 'ansible-inventory -i hosts.ini --graph'

block resolved
on admin "ansible all -i hosts.ini -f 1 -m debug -a 'msg=\"tries={{ ssh_max_auth_tries }} x11={{ x11_forwarding }}\"' | grep -E 'SUCCESS|msg'"

block before
on admin "ansible all -i hosts.ini -f 1 -b -m shell -a \"sshd -T | grep -E '^(maxauthtries|x11forwarding) '\" | sed 's/ | CHANGED | rc=0 >>//'"

block apply
on admin 'ansible-playbook -i hosts.ini baseline.yml | tail -6'

block after
on admin "ansible all -i hosts.ini -f 1 -b -m shell -a \"sshd -T | grep -E '^(maxauthtries|x11forwarding|banner) '\" | sed 's/ | CHANGED | rc=0 >>//'"

block hand-edit
on desk 'sudo sed -i "s/^MaxAuthTries .*/MaxAuthTries 10/" /etc/ssh/sshd_config.d/10-baseline.conf; grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf'

block check-diff
on admin 'ansible-playbook -i hosts.ini baseline.yml --check --diff --limit desk | grep -E "^[-+]|changed=|TASK \[SSH"'
on desk 'grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf'

write admin baseline.service <<'EOF'
[Unit]
Description=Put the Jatoba baseline back on every machine

[Service]
Type=oneshot
User=ana
WorkingDirectory=/home/ana
Environment=ANSIBLE_NOCOLOR=1
ExecStart=/usr/bin/ansible-playbook -i hosts.ini baseline.yml
EOF
write admin baseline.timer <<'EOF'
[Unit]
Description=Run the Jatoba baseline every hour

[Timer]
OnCalendar=hourly
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

block units
on admin 'cat baseline.service baseline.timer'

block timer
on admin 'sudo cp baseline.service baseline.timer /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now baseline.timer 2>&1 | sed "s/ → .*//"'
on admin 'systemctl list-timers baseline.timer --no-pager | head -2 | cut -c1-95'

block run-now
on admin 'sudo systemctl start baseline.service; journalctl -u baseline.service --no-pager -o cat | grep -E "^(desk|jump|web) "'
on desk 'grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf'

rm -rf "$files"
