#!/usr/bin/env bash
# The terminal session quoted in lesson 17 of git, as a script that produces it.
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
# Bruno's check-links.sh is the file the copy button of checks-on-a-clean-machine
# gives; it, the shared copy and Ana's change for #34, picture included, are the
# ```bash blocks works-on-my-machine prints, run by `given`.
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
# example FILE N: the file the Nth schooling-example of FILE gives to its copy
# button, which joins the parts' code with a newline.
example() {
  python3 -c 'import json, re, sys
blocks = re.findall(r"^```schooling-example\n(.*?)\n```$", open(sys.argv[1]).read(), re.S | re.M)
print("\n".join(p["code"] for p in json.loads(blocks[int(sys.argv[2]) - 1])["parts"]))' "$1" "$2"
}

git config --global color.ui never
git config --global color.advice never
git config --global color.remote never
tty() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}
# Bruno's check, the shared copy and Ana's change for #34: the two blocks
# works-on-my-machine prints, with check-links.sh between them saved from the
# copy button of the example that checks-on-a-clean-machine prints.
cd ~ && given works-on-my-machine 1
example "$lessons/$self/checks-on-a-clean-machine.md" 1 > check-links.sh
given works-on-my-machine 2 '2026-09-19T11:00:00-03:00'
me

block status
show 'git status --short'
at '2026-09-29T10:00:00-03:00'
show "git commit -qam 'Show allergens on the menu' -m 'Refs #34'"
show './check-links.sh && echo all links found'
show 'git push -q -u origin 34-allergens'

block fresh
show 'git clone -q --branch 34-allergens ~/remotes/site.git /tmp/fresh'
show 'cd /tmp/fresh'
tty 'ls'
show './check-links.sh && echo all links found'

block fixed
cd ~/site
show 'git status --short'
show 'git add images/allergens.png'
at '2026-09-29T10:20:00-03:00'
show "git commit -qm 'Add the allergens picture' -m 'Refs #34'"
show 'git status --short'
