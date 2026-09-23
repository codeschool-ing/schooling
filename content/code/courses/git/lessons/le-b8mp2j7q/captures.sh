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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; and the edits each
# branch commits, made with sed or printf between the commands shown.
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
git config --global user.name 'Ana Souza'
git config --global user.email 'ana@example.com'
git config --global init.defaultBranch main
git config --global core.editor nano

# The week of lesson 3, rebuilt: nine commits by Ana and Bruno.
cd ~ && rm -rf ~/site
mkdir ~/site && cd ~/site && git init -q
bruno() { as 'Bruno Lima' 'bruno@example.com'; }
c() { git add -A && git commit -q -m "$1"; }
me; at '2026-09-14T09:05:00-03:00'
printf '<h1>Padaria Sol</h1>\n<p>Bread from six in the morning.</p>\n' > index.html; c 'Add the home page'
at '2026-09-14T10:20:00-03:00'
printf 'h1 { color: darkorange; }\n' > style.css; c 'Give the heading its colour'
at '2026-09-14T14:10:00-03:00'
printf '<h1>Menu</h1>\n<p>French bread, 0.80</p>\n' > menu.html; c 'Add the menu'
bruno; at '2026-09-15T11:02:00-03:00'
printf '<p>Rye bread, 1.20</p>\n' >> menu.html; c 'Add rye bread to the menu'
me; at '2026-09-16T09:40:00-03:00'
sed -i 's/six in the morning/half past five/' index.html; c 'Open at half past five'
bruno; at '2026-09-16T16:25:00-03:00'
sed -i 's/0.80/0.90/; s/1.20/1.35/' menu.html; c 'Put the prices up for September'
me; at '2026-09-17T10:15:00-03:00'
printf '<p>Cheese roll, 2.50</p>\n' >> menu.html; c 'Add cheese rolls'
bruno; at '2026-09-18T08:50:00-03:00'
sed -i '/Rye bread/d' menu.html; c 'Take rye bread off until the flour arrives'
me; at '2026-09-18T15:30:00-03:00'
printf '<p><a href="menu.html">See the menu</a></p>\n' >> index.html; c 'Link the menu from the home page'


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
sed -i 's/half past five/half past five; Sundays from seven/' index.html
show 'git commit -qam "Open on Sundays from seven"'
show 'git log --oneline -2'
show 'git switch main'
show 'cat index.html'

block carry
printf 'h1 { color: darkorange; }\np { line-height: 1.5; }\n' > style.css
show 'git status --short'
show 'git switch opening-hours'
show 'git status --short'
show 'git switch main'
git restore style.css

block refuse
sed -i 's/half past five/half past six/' index.html
show 'git switch opening-hours'
git restore index.html

block fast-forward
show 'git merge opening-hours'
show 'git log --oneline -3'

block diverge
at '2026-09-21T11:00:00-03:00'
show 'git switch -c menu-prices'
sed -i 's/0.90/0.95/' menu.html
show 'git commit -qam "Charge 0.95 for French bread"'
show 'git switch main'
at '2026-09-21T11:30:00-03:00'
printf 'h1 { color: darkorange; }\np { line-height: 1.5; }\n' > style.css
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
sed -i 's/darkorange/purple/' style.css
show 'git commit -qam "Try purple"'
show 'git switch main'
show 'git branch -v'
show 'git branch --merged'
show 'git branch -d menu-prices opening-hours'
show 'git branch -d experiment'
show 'git branch -D experiment'
show 'git branch'
