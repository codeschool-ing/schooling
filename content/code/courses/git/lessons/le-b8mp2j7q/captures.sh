#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of git, as a script that produces them.
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
# Nothing the student types is staged. Lesson 3's week is the program lesson 3
# prints, started afresh by the block what-a-branch-is prints, and the edits
# each branch commits are typed in the transcripts, with sed or printf, where a
# person would use an editor.
#
# What is STAGED rather than typed: the date of each commit, so that the ids
# printed in the prose are reproducible.
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
cd ~ && given what-a-branch-is 1


block pointer
show 'git branch'
show 'cat .git/HEAD'
show 'cat .git/refs/heads/main'
show 'git branch opening-hours'
show 'git branch'
show 'cat .git/refs/heads/opening-hours'

block switch
at '2026-09-21T09:10:00-03:00'
show 'git switch opening-hours'
show 'cat .git/HEAD'
show "sed -i 's/half past five/half past five; Sundays from seven/' index.html"
show 'git commit -qam "Open on Sundays from seven"'
show 'git log --oneline -2'
show 'git switch main'
show 'cat index.html'

block carry
show "printf 'h1 { color: darkorange; }\\np { line-height: 1.5; }\\n' > style.css"
show 'git status --short'
show 'git switch opening-hours'
show 'git status --short'
show 'git switch main'
show 'git restore style.css'

block refuse
show "sed -i 's/half past five/half past six/' index.html"
show 'git switch opening-hours'
show 'git restore index.html'

block fast-forward
show 'git merge opening-hours'
show 'git log --oneline -3'

block diverge
at '2026-09-21T11:00:00-03:00'
show 'git switch -c menu-prices'
show "sed -i 's/0.90/0.95/' menu.html"
show 'git commit -qam "Charge 0.95 for French bread"'
show 'git switch main'
at '2026-09-21T11:30:00-03:00'
show "printf 'h1 { color: darkorange; }\\np { line-height: 1.5; }\\n' > style.css"
show 'git commit -qam "Give paragraphs more room"'
show 'git log --oneline --graph --all -4'

block true-merge
at '2026-09-21T12:00:00-03:00'
show 'git merge --no-edit menu-prices'
show 'git log --oneline --graph -5'
show 'git cat-file -p HEAD'

block delete
at '2026-09-21T14:00:00-03:00'
show 'git switch -c experiment'
show "sed -i 's/darkorange/purple/' style.css"
show 'git commit -qam "Try purple"'
show 'git switch main'
show 'git branch -v'
show 'git branch --merged'
show 'git branch -d menu-prices opening-hours'
show 'git branch -d experiment'
show 'git branch -D experiment'
show 'git branch'
