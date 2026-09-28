#!/usr/bin/env bash
# Lesson 14 of portfolio-project: secrets, and what must never reach the repository.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
# THE LAB IS TWO MACHINES. laptop is where ana writes the project; srv is the
# server she deploys it to. Both run Ubuntu 24.04 and share a private network
# (laptop is 10.20.0.10, srv is 10.20.0.20), and ana's key on laptop opens her
# account on srv. A line that starts with ana@laptop ran on laptop, and one that
# starts with ana@srv ran on srv, reached with ssh. The path after the colon is
# the directory the command ran in.
#
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the project's history, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh      # on laptop
#
# The project is loanbook, built step by step by lab.sh with the dates written
# there; `lab stage N` rebuilds ~/loanbook at step N, quietly.
#
# Both machines are containers (systemd-nspawn) on the computer that recorded
# the course, and srv's /etc/containers/containers.conf turns off the pids limit
# a container inside a container cannot have. Nothing a lesson shows depends
# on it.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - ~/loanbook is rebuilt at step 14 (lab.sh), and one item added.
#   - notify.py is written by printf, twice with a made-up password and once reading
#     the environment, and the pre-commit hook by a heredoc. The password is invented:
#     no SMTP server has it.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3.12, git 2.43, Podman 4.9 and Caddy 2.6,
# TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
lab() { bash /var/tmp/lab.sh "$@" >/dev/null 2>&1; }
# on MACHINE DIR 'command': what ana typed at her prompt, in DIR (relative to
# her home, "~" for the home itself), on laptop or on srv through ssh, and
# everything it printed.
on() {
  local h=$1 d=$2; shift 2
  local shown=$([ "$d" = "~" ] && echo "~" || echo "~/$d")
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd $HOME/$d")
  printf 'ana@%s:%s$ %s\n' "$h" "$shown" "$*"
  if [ "$h" = laptop ]; then ($cd && bash -c "$*") 2>&1 || true
  else ssh srv "$cd && $*" 2>&1 || true; fi
}
# The same, not shown: the lab's own housekeeping.
quiet() {
  local h=$1 d=$2; shift 2
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd $HOME/$d")
  if [ "$h" = laptop ]; then ($cd && bash -c "$*") >/dev/null 2>&1 || true
  else ssh srv "$cd && $*" >/dev/null 2>&1 || true; fi
}
block() { printf '##### %s\n' "$1"; }

lab stage 14
block env-diff
on laptop loanbook 'git show --format=%s HEAD -- app.py .gitignore'
block env-run
quiet laptop loanbook 'python3 app.py add "Projector 1"'
on laptop loanbook 'LOANBOOK_DB=/tmp/other.db LOANBOOK_PORT=8001 timeout 2 python3 app.py'
on laptop loanbook 'ls *.db /tmp/other.db'
block leak
on laptop loanbook 'git switch -q -c reminders'
quiet laptop loanbook "printf 'SMTP_HOST = \"smtp.example.org\"\nSMTP_USER = \"loanbook@example.org\"\nSMTP_PASSWORD = \"mR7vQ2xL9pT4wZ8k\"\n' > notify.py"
on laptop loanbook 'cat notify.py'
on laptop loanbook 'git add notify.py'
on laptop loanbook "git commit -q -m 'Send a reminder the day a loan is due'"
on laptop loanbook 'git rm -q notify.py'
on laptop loanbook "git commit -q -m 'Remove the reminder for now'"
on laptop loanbook 'ls notify.py'
block still-there
on laptop loanbook "git log --oneline -S mR7vQ2xL9pT4wZ8k"
on laptop loanbook "git show HEAD~1:notify.py | grep PASSWORD"
block unpushed
on laptop loanbook 'git switch -q main'
on laptop loanbook 'git branch -D reminders'
on laptop loanbook "git log --all --oneline -S mR7vQ2xL9pT4wZ8k | wc -l"
block hook
quiet laptop loanbook "cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
# Refuse a commit whose added lines look like a secret being assigned.
if git diff --cached -U0 | grep -inE '^\+.*(password|secret|token|api_?key)[a-z_]*[[:space:]]*[=:][[:space:]]*[\"'\''][^\"'\'']{8,}'; then
  echo 'pre-commit: that looks like a secret. Keep it in the environment, not the repository.' >&2
  exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit"
on laptop loanbook 'cat .git/hooks/pre-commit'
quiet laptop loanbook "printf 'SMTP_HOST = \"smtp.example.org\"\nSMTP_PASSWORD = \"mR7vQ2xL9pT4wZ8k\"\n' > notify.py"
on laptop loanbook 'git add notify.py'
on laptop loanbook "git commit -q -m 'Send a reminder the day a loan is due'"
on laptop loanbook 'git log --oneline -1'
quiet laptop loanbook "printf 'import os\n\nSMTP_HOST = os.environ[\"SMTP_HOST\"]\nSMTP_PASSWORD = os.environ[\"SMTP_PASSWORD\"]\n' > notify.py"
block hook-ok
on laptop loanbook 'cat notify.py'
on laptop loanbook 'git add notify.py'
on laptop loanbook "git commit -q -m 'Send a reminder the day a loan is due'"
on laptop loanbook 'git log --oneline -1'
