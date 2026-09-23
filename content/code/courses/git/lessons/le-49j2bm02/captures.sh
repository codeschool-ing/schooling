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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; the tag v1.0 on
# where it ends; Bruno's task (#21, pull request #22) merged the day before;
# the two pull requests' merges made with `git merge --no-ff` and the message
# GitHub's merge button writes, because the button is a website and this is a
# terminal; the pull and the review happen on the platform and are not shown
# here, so `git pull` has no remote to ask; colour switched off.
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

cd ~ && rm -rf ~/remotes ~/platform
git config --global color.ui never
git config --global color.advice never
git config --global color.remote never
tty() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}
cd ~/site && git tag -a v1.0 -m 'The site as it went live' HEAD
git init -q --bare ~/remotes/site.git
git remote add origin ~/remotes/site.git
git push -q -u origin main v1.0 2>/dev/null

# The platform's merge button, played by a clone that merges and pushes.
git clone -q ~/remotes/site.git ~/platform/site 2>/dev/null
merge() {  # merge BRANCH NUMBER AUTHOR TITLE
  ( cd ~/platform/site && as 'GitHub' 'noreply@github.com' && git fetch -q origin &&
    git merge -q --ff-only origin/main && git merge -q --no-ff "origin/$1" -m "Merge pull request #$2 from $3/$1" -m "$4" &&
    git push -q origin main && git push -q origin --delete "$1" )
}

# Bruno's task, #21, done on his own machine the day before and merged as #22.
bruno; at '2026-09-21T10:00:00-03:00'
git switch -q -c 21-rye-bread-back
printf '<p>Rye bread, 1.35</p>\n' >> menu.html; git commit -qam 'Put rye bread back on the menu' -m 'Refs #21'
git push -q origin 21-rye-bread-back 2>/dev/null
git switch -q main && git branch -q -D 21-rye-bread-back && git reset -q --hard v1.0
at '2026-09-21T15:00:00-03:00'; merge 21-rye-bread-back 22 bruno 'Put rye bread back on the menu'
me

block branch
at '2026-09-22T09:10:00-03:00'
show 'git switch main'
tty 'git pull'
show 'git switch -c 23-holiday-notice'

block commits
at '2026-09-22T09:40:00-03:00'
printf '<p>Closed on public holidays.</p>\n' >> index.html; git commit -qam 'Say the bakery closes on public holidays' -m 'Refs #23'
at '2026-09-22T10:05:00-03:00'
printf '.closed { font-weight: bold; }\n' >> style.css
sed -i 's|<p>Closed on public holidays.</p>|<p class="closed">Closed on public holidays.</p>|' index.html
git commit -qam 'Make the holiday notice stand out' -m 'Refs #23'
show 'git log --oneline main..'
tty 'git push -u origin 23-holiday-notice'

at '2026-09-22T16:30:00-03:00'; merge 23-holiday-notice 24 ana 'Say the bakery closes on public holidays'
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
