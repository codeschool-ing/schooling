#!/usr/bin/env bash
# Lesson 9 of portfolio-project: commits that read like a story.
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
#   - ~/loanbook is rebuilt at step 20; then at step 12 with step 13's files written
#     and not committed, plus one debug line added to app.py by sed; then at step 20
#     again (lab.sh). The commits made on camera are dated the day the script ran.
#   - The fixup renames a test by sed before committing it.
#   - git add -p reads its answers, y then n, from printf rather than the keyboard,
#     so each prompt is followed on the same line by what came next.
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

lab stage 20
block story
on laptop loanbook 'git log --oneline --reverse'
lab stage 12
bash /var/tmp/lab.sh write 13 >/dev/null 2>&1
quiet laptop loanbook "sed -i 's/^            body = json.loads(.*/&\n            print(\"DEBUG body\", body)/' app.py"
block status
on laptop loanbook 'git status --short'
block addp
on laptop loanbook "printf 'y\nn\n' | git add -p app.py"
block left
on laptop loanbook 'git diff'
on laptop loanbook 'git restore app.py'
on laptop loanbook 'git add test_app.py'
on laptop loanbook "git commit -q -m 'Refuse a borrower made of spaces' -m 'The test came first, and it failed: \"   \" was accepted as a name.'"
block fixup
quiet laptop loanbook "sed -i 's/test_a_borrower_made_of_spaces_is_refused/test_a_name_made_of_spaces_is_refused/' test_app.py"
on laptop loanbook 'git commit -q -a --fixup HEAD'
on laptop loanbook 'git log --oneline -3'
on laptop loanbook 'GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash HEAD~2'
on laptop loanbook 'git log --oneline -3'
lab stage 20
block read
on laptop loanbook "git log --format='%h %ad %s' --date=short v0.2.0..v0.3.0"
