#!/usr/bin/env bash
# The terminal session quoted in lesson 14 of git, as a script that produces it.
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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; a bare
# repository standing in for the hosting service; lesson 13's pull request
# #31, committed in a second clone that plays Bruno's machine, whose prompt
# the helpers print; the edits made with sed where Bruno would use an editor;
# colour switched off.
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
cd ~ && rm -rf ~/site && bash ~/make-site.sh && cd ~/site
me; at '2026-09-18T15:30:00-03:00'

cd ~ && rm -rf ~/remotes ~/bruno
git config --global color.ui never
git config --global color.advice never
git config --global color.remote never
cd ~/site
git init -q --bare ~/remotes/site.git
git remote add origin ~/remotes/site.git
git push -q -u origin main 2>/dev/null

# Lesson 13's pull request #31, as Bruno pushed it.
git clone -q ~/remotes/site.git ~/bruno/site 2>/dev/null
cd ~/bruno/site && bruno
git config user.name 'Bruno Lima' && git config user.email 'bruno@example.com'
git switch -q -c 30-pickup-times
at '2026-09-24T10:10:00-03:00'
printf '<h1>Order ahead</h1>\n<form class="order">\n  <label>Pickup time <input name="pickup" type="time"></label>\n  <button>Order</button>\n</form>\n' > order.html
printf '<p><a href="order.html">Order ahead</a></p>\n' >> index.html
git add -A && git commit -qm 'Let customers choose a pickup time' -m 'Refs #30'
at '2026-09-24T10:40:00-03:00'
sed -i 's/darkorange/saddlebrown/' style.css && printf '.order label { display: block; }\n' >> style.css
git commit -qam 'Style the order form' -m 'Refs #30'
git push -q -u origin 30-pickup-times 2>/dev/null

# From here the terminal is Bruno's, in his own clone.
where() { pwd | sed "s|^$HOME/bruno|~|"; }
show() { printf 'bruno@vm:%s$ %s\n' "$(where)" "$*"; eval "$*" 2>&1 || true; }
tty() { printf 'bruno@vm:%s$ %s\n' "$(where)" "$*"; script -qec "$*" /dev/null || true; }

block fix
at '2026-09-25T09:20:00-03:00'
sed -i 's|type="time">|type="time" min="06:00" max="19:00" required>|' order.html
show 'git diff'
show "git commit -qam 'Require a pickup time within opening hours' -m 'Refs #30'"

block scope
at '2026-09-25T09:35:00-03:00'
sed -i 's/saddlebrown/darkorange/' style.css
show "git commit -qam 'Leave the heading colour for its own pull request' -m 'Refs #30'"
show 'git diff main... -- style.css'

block push
show 'git log --oneline main..'
tty 'git push'

block colour
at '2026-09-25T09:50:00-03:00'
show 'git switch -c 32-heading-colour main'
sed -i 's/darkorange/saddlebrown/' style.css
show "git commit -qam 'Darken the heading colour' -m 'Refs #32'"
tty 'git push -u origin 32-heading-colour'
