#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of git, as a script that produces them.
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
# The week of the bakery's site is NOT staged: it is make-site.sh, the program
# `the-week` prints, read out of that page by `fence` and run, so the program a
# student copies and the one recorded here are the same bytes. Every later
# lesson starts from it the same way.
#
# The edit the first diff reads is the block reading-a-diff prints, run by
# `given`, and so is the one that puts it back; the `git diff` after it is not
# quoted and is there to show that it prints nothing, as the prose says.
#
# What is STAGED rather than typed, and not shown in the lesson: lesson 2's
# ~/site, an empty folder for `mv` to move aside.
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

bruno() { as 'Bruno Lima' 'bruno@example.com'; }
c() { git add -A && git commit -q -m "$1"; }

# The week, made the way the-week tells the student to: the program saved from
# its page, lesson 2's ~/site moved aside (an empty folder stands in for it), and
# the program run. Then once more from scratch, the way a later lesson restarts.
fence "$lessons/le-5gv65sh1/the-week.md" 1 > ~/make-site.sh
cd ~ && rm -rf ~/site ~/site-lesson-2 && mkdir ~/site
block the-week
show 'mv site site-lesson-2'
show 'bash make-site.sh'
show 'cd site'
show 'git log --oneline -3'
block the-week-again
cd ~
show 'rm -rf ~/site && bash ~/make-site.sh'
cd ~/site && rm -rf ~/site-lesson-2
me; at '2026-09-18T15:30:00-03:00'

block log-default
show 'git log -2'

block log-oneline
show 'git log --oneline'

block log-stat
show 'git log --stat -1 HEAD~3'

block log-filters
show 'git log --oneline --author=Bruno'
show 'git log --oneline -- index.html'
show 'git log --oneline --since="2026-09-17 00:00"'
show 'git log --oneline --grep=price'

block diff-work
given reading-a-diff 1
show 'git diff'

block diff-commits
given reading-a-diff 2
show 'git diff'
show 'git diff HEAD~3 HEAD -- menu.html'

block diff-stat
show 'git diff --stat HEAD~3 HEAD'

block show-commit
show 'git show HEAD~3'

block show-file
show 'git show HEAD~3:menu.html'

block blame
show 'git blame menu.html'

block pickaxe
show 'git log -S "Rye" --oneline'
