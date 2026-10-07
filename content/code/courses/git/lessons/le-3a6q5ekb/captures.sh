#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of git, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it against
# a newer Git and see what moved. Lesson 1's captures.sh says why it exists.
#
#   sudo useradd -m -s /bin/bash ana     # once, on a throwaway machine
#   sudo -u ana -i bash /path/to/captures.sh
#
# It rewrites ~/.gitconfig to lesson 1's four settings and deletes the
# directories it builds before it starts, which is why it wants a throwaway
# account. `block NAME` marks where a transcript in the prose begins.
#
# Nothing the student types is staged any more. Lesson 3's week is the program
# lesson 3 prints, and the edits the undo commands undo and the two colour
# commits are the ```bash blocks this lesson prints, run by `given`.
#
# What is STAGED rather than typed: the date of each commit, and the author of
# the revert, Bruno, so that the ids printed in the prose are reproducible.
# Every line after a prompt is what the command printed.
#
# Recorded with git 2.43.0 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 GIT_PAGER=cat PAGER=cat
show() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  eval "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
at() { export GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1"; }
as() { export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2" GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"; }
me() { as 'Ana Souza' 'ana@example.com'; }

# Where the lessons are, so that a block can be read out of the page that prints
# it: what the capture runs and what the student is shown cannot then drift.
lessons=$(cd "$(dirname "$0")/.." && pwd)
self=$(basename "$(cd "$(dirname "$0")" && pwd)")
# fence FILE N: the Nth ```bash block of FILE, exactly as the lesson prints it.
fence() {
  local body
  body=$(awk -v n="$2" '/^```bash$/ { if (++c == n) { f = 1; next } } f && /^```$/ { exit } f' "$1")
  [ -n "$body" ] || { echo "no bash block $2 in $1" >&2; exit 1; }
  printf '%s\n' "$body"
}
# given SECTION N [DATE...]: run the Nth ```bash block of this lesson's SECTION
# one line at a time, as somebody pasting it would. Each line that makes a
# commit is dated with the next DATE, the one thing a capture adds. Names come
# from the settings and from the block's own `-c user.name=…`, so the exported
# identity is set aside while it runs and put back afterwards.
given() {
  local md="$lessons/$self/$1.md" n=$2 line name=${GIT_AUTHOR_NAME-} email=${GIT_AUTHOR_EMAIL-}
  shift 2
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  # With no dates there is nothing to place between lines, and the block runs
  # whole, which is what lets one hold a here-document.
  if [ $# -eq 0 ]; then
    eval "$(fence "$md" "$n")"
  else while IFS= read -r line; do
    case $line in ''|'#'*) continue ;; esac
    if [ $# -gt 0 ] && [[ $line =~ (^|[\;\&\ ])git\ (.*\ )?(commit|merge|revert|rebase|cherry-pick|pull|tag\ -a)(\ |$) ]]; then
      at "$1"; shift
    fi
    eval "$line"
  done < <(fence "$md" "$n"); fi
  [ -z "$name" ] || as "$name" "$email"
}
git config --global user.name 'Ana Souza'
git config --global user.email 'ana@example.com'
git config --global init.defaultBranch main
git config --global core.editor nano

# The week of lesson 3, rebuilt: nine commits by Ana and Bruno.
bruno() { as 'Bruno Lima' 'bruno@example.com'; }
c() { git add -A && git commit -q -m "$1"; }
# Lesson 3's week, made by the program lesson 3 prints, read out of its page.
fence "$lessons/le-5gv65sh1/the-week.md" 1 > ~/make-site.sh
me; at '2026-09-18T15:30:00-03:00'


cd ~ && given restore 1
block restore-worktree
at '2026-09-21T09:00:00-03:00'
given restore 2
show 'git diff --stat'
show 'git restore menu.html'
show 'git status --short'

block restore-staged
given restore 3
show 'git add menu.html'
show 'git status --short'
show 'git restore --staged menu.html'
show 'git status --short'

block restore-source
show 'git restore --source=HEAD~3 menu.html'
show 'cat menu.html'
show 'git status --short'
show 'git restore menu.html'

block revert
bruno; at '2026-09-21T10:30:00-03:00'
show 'git revert --no-edit HEAD~1'
show 'git log --oneline -3'
show 'cat menu.html'

block amend
me; at '2026-09-21T11:05:00-03:00'
given reset-and-amend 1
show 'git commit -m "Close on Sundys"'
show 'git commit --amend -m "Close on Sundays"'
show 'git log --oneline -2'

block reset-soft
given reset-and-amend 2 '2026-09-21T14:00:00-03:00' '2026-09-21T14:20:00-03:00'
show 'git log --oneline -3'
show 'git reset --soft HEAD~1'
show 'git status --short'
show 'git log --oneline -2'

block reset-mixed
show 'git reset HEAD~1'
show 'git status --short'
show 'git diff'

block reset-hard
show 'git reset --hard'
show 'git status --short'
show 'git log --oneline -2'

block reflog
show 'git reflog -6'

block recover
show 'git reset --hard HEAD@{3}'
show 'git log --oneline -3'
show 'cat style.css'
