#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of git, as a script that produces them.
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
# The files each scene needs, the commits around them and the shared-styles
# repository the submodule points at are the ```bash blocks the lesson prints,
# run by `given`; .gitignore is the file its schooling-example's copy button
# gives; the photos are made by commands typed in the transcripts. Git refuses
# a submodule from a local folder by default, and the lesson shows the
# `-c protocol.file.allow=always` that allows it for one command. Needs
# git-lfs installed (3.4.1 here).
#
# What is STAGED rather than typed: the date of each commit, so that the ids in
# the prose are reproducible.
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

block before-ignore
cd ~ && given gitignore 1
show 'git status --short'

block after-ignore
example "$lessons/$self/gitignore.md" 1 > .gitignore
show 'git status --short'
show 'git check-ignore -v debug.log node_modules/lightbox/index.js'

block gitignore-file
show 'cat .gitignore'
given gitignore 2 '2026-09-21T09:00:00-03:00'

block tracked
given tracked-and-secrets 1 '2026-09-21T09:10:00-03:00' '2026-09-21T09:10:00-03:00'
at '2026-09-21T09:10:00-03:00'
show 'git status --short'
show 'git rm --cached settings.local'
show 'git status --short'
show 'git commit -qm "Stop tracking local settings"'
show 'git status --short'

block secret
given tracked-and-secrets 2 '2026-09-21T10:00:00-03:00' '2026-09-21T10:05:00-03:00'
show 'git log --oneline -2'
show 'ls .env && git status --short'
show 'git show HEAD~1:.env'

block growth
at '2026-09-21T11:00:00-03:00'
show 'du -sh .git'
show 'for i in 1 2 3; do head -c 1048576 /dev/urandom > photo.jpg; git add photo.jpg; git commit -qm "Photo of the shop front, take $i"; done'
show 'du -h photo.jpg'
show 'du -sh .git'

block lfs
show 'cd ~ && mkdir photos && cd photos && git init -q'
show 'git lfs install'
show 'git lfs track "*.jpg"'
show 'cat .gitattributes'
show "head -c 1048576 /dev/zero | tr '\\0' 'a' > front.jpg"
at '2026-09-21T12:00:00-03:00'
show 'git add .gitattributes front.jpg'
show 'git commit -qm "Add the shop front photo"'
show 'git lfs ls-files'
show 'git show HEAD:front.jpg'

block submodule
cd ~/site && given submodules 1 '2026-09-20T10:00:00-03:00'
at '2026-09-21T13:00:00-03:00'
show 'git -c protocol.file.allow=always submodule add ~/remotes/shared-styles.git styles'
show 'cat .gitmodules'
show 'git status --short'
show 'git commit -qm "Use the shared brand styles"'
show 'git submodule status'
given submodules 2

block submodule-clone
cd ~
show 'git clone -q ~/remotes/site.git copy && cd copy'
show 'ls styles'
show 'git -c protocol.file.allow=always submodule update --init'
show 'ls styles'
