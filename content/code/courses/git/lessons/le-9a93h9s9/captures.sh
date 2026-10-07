#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of git, as a script that produces them.
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
# Both people's work is typed: Bruno's in his clone, ~/bruno/site, with his name
# set in that repository as the lesson shows, and the commits that make the two
# copies diverge in the ```bash block `rejected` prints, run by `given`.
#
# What is STAGED rather than typed: the date of each commit, so that the ids in
# the prose are reproducible; colour switched off, since a transcript has none.
# The push, fetch, pull and clone commands run under `script`, a
# pseudo-terminal, because git only prints its progress to a terminal and a
# reader at one sees it.
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
cd ~ && given origin 1
git config --global color.ui never
git config --global color.push never
git config --global color.advice never
git config --global color.remote never
# Run a command as it would run in a terminal, where git prints its progress.
tty() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}

block bare
show 'git init --bare ~/remotes/site.git'

block add-push
show 'cd site'
show 'git remote add origin ~/remotes/site.git'
show 'git remote -v'
tty 'git push -u origin main'

block clone
cd ~
show 'mkdir bruno && cd bruno'
tty 'git clone ~/remotes/site.git'
show 'cd site'
show 'git config user.name "Bruno Lima"'
show 'git config user.email "bruno@example.com"'
show 'git branch -a'

block bruno-push
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
at '2026-09-21T10:15:00-03:00'
show "sed -i 's/Cheese roll, 2.50/Cheese roll, 2.60/' menu.html"
show 'git commit -qam "Charge 2.60 for cheese rolls"'
tty 'git push'

block stale
cd ~/site
me
show 'git status'

block fetch
tty 'git fetch'
show 'git status'
show 'git log --oneline --all -3'

block pull
tty 'git pull'

block diverge
given rejected 1 '2026-09-21T11:00:00-03:00' '2026-09-21T11:20:00-03:00'
me
at '2026-09-21T11:30:00-03:00'

block rejected
tty 'git push'

block pull-diverged
tty 'git pull'

block pull-rebase
tty 'git pull --rebase'
tty 'git push'
show 'git log --oneline -3'

block tags
at '2026-09-21T12:00:00-03:00'
show 'git tag -a v1.0 -m "The site as it went live"'
show 'git tag'
show 'git show v1.0 --no-patch'
tty 'git push origin v1.0'

block delete-remote-branch
show 'git switch -c autumn-menu'
tty 'git push -u origin autumn-menu'
show 'git switch main'
tty 'git push origin --delete autumn-menu'
