#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of git, as a script that produces them.
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
# The shared copy, Bruno's task #21 and pull request #22, Ana's two commits and
# the merges of both pull requests are the ```bash blocks the lesson prints,
# run by `given`. The hosting service's merge button is merge-button.sh, which
# the-ticket prints whole: a clone of the shared copy in ~/platform that merges
# with `--no-ff` and the message GitHub's button writes, because the button is
# a website and this is a terminal. The review happens on the platform and is
# not shown.
#
# What is STAGED rather than typed: the date of each commit, so that the ids in
# the prose are reproducible; colour switched off.
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
# given SECTION N [DATE...]: run the Nth ```bash block of this lesson's SECTION,
# as somebody pasting it would. Each git command in it that makes a commit or a
# tag is dated with the next DATE, the one thing a capture adds, and a DATE left
# over is an error: the block and the dates have stopped agreeing. Names come
# from the settings and from the block's own `-c user.name=…`, so the exported
# identity is set aside while it runs and put back afterwards.
given() {
  local section=$1 md="$lessons/$self/$1.md" n=$2 name=${GIT_AUTHOR_NAME-} email=${GIT_AUTHOR_EMAIL-}
  shift 2
  dates=("$@")
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  git() {
    local a skip= sub=
    for a in "$@"; do
      if [ -n "$skip" ]; then skip=; continue; fi
      case $a in -c|-C) skip=1 ;; -*) ;; *) sub=$a; break ;; esac
    done
    case $sub in commit|merge|revert|rebase|cherry-pick|pull|tag)
      if [ ${#dates[@]} -gt 0 ]; then at "${dates[0]}"; dates=("${dates[@]:1}"); fi ;;
    esac
    command git "$@"
  }
  eval "$(fence "$md" "$n")"
  unset -f git
  [ ${#dates[@]} -eq 0 ] || { echo "given $section $n: ${#dates[@]} date(s) left over" >&2; exit 1; }
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

git config --global color.ui never
git config --global color.advice never
git config --global color.remote never
tty() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}

# The shared copy with v1.0 on it, the merge button, and Bruno's task #21,
# done the day before and merged as #22: the-ticket's four blocks, in order.
cd ~ && given the-ticket 1 '2026-09-18T15:30:00-03:00'
fence "$lessons/$self/the-ticket.md" 2 > ~/merge-button.sh
given the-ticket 3 '2026-09-21T10:00:00-03:00'
at '2026-09-21T15:00:00-03:00'
given the-ticket 4
me

block branch
at '2026-09-22T09:10:00-03:00'
show 'git switch main'
tty 'git pull'
show 'git switch -c 23-holiday-notice'

block commits
given branch-to-pull-request 1 '2026-09-22T09:40:00-03:00' '2026-09-22T10:05:00-03:00'
show 'git log --oneline main..'
tty 'git push -u origin 23-holiday-notice'

at '2026-09-22T16:30:00-03:00'
given review-merge-release 1
me
block merged
show 'git switch main'
tty 'git pull'
show 'git branch -d 23-holiday-notice'
show 'git log --oneline --graph -7'

block release
at '2026-09-23T09:00:00-03:00'
show "git tag -a v1.1 -m 'Holiday notice, rye bread back'"
tty 'git push origin v1.1'
show 'git log --oneline --no-merges v1.0..v1.1'

block contains
show 'git log --oneline --grep "#23"'
id=$(git log --format=%h --grep '#23' | tail -1)
show "git tag --contains $id"
