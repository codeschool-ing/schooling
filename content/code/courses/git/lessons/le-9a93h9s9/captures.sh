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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; the shared
# repository, a bare one in ~/remotes, standing in for GitHub; Bruno's copy,
# a second clone on the same machine; the edits each of them commits; and
# colour switched off, since a transcript has none. The push, fetch, pull and
# clone commands run under `script`, a pseudo-terminal, because git only
# prints its progress to a terminal and a reader at one sees it.
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

cd ~ && rm -rf ~/remotes ~/bruno
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
cd ~/site
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
sed -i 's/Cheese roll, 2.50/Cheese roll, 2.60/' menu.html
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
at '2026-09-21T11:00:00-03:00'
sed -i 's/half past five/half past five, Monday to Saturday/' index.html
show 'git commit -qam "Say which days we open"'
cd ~/bruno/site
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
at '2026-09-21T11:20:00-03:00'
printf 'h1 { color: darkorange; }\np { line-height: 1.5; }\n' > style.css
git commit -qam 'Give paragraphs more room'
git push -q
cd ~/site
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
git switch -q -c autumn-menu
tty 'git push -u origin autumn-menu'
git switch -q main
tty 'git push origin --delete autumn-menu'
