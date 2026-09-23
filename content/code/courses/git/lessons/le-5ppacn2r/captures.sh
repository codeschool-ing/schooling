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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; Bruno's
# check-links.sh committed on top of it; a bare repository standing in for
# the hosting service; the allergens picture, which is three bytes and not a
# picture, and the line of menu.html that shows it, both written by the
# script; colour switched off.
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

cd ~ && rm -rf ~/remotes /tmp/fresh
git config --global color.ui never
git config --global color.advice never
git config --global color.remote never
tty() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}
cd ~/site
cat > check-links.sh <<'SH'
#!/bin/sh
# Fail if any page links to a file that is not in the repository.
status=0
for f in $(grep -oh '\(src\|href\)="[^":]*"' *.html | cut -d'"' -f2 | sort -u); do
  [ -e "$f" ] || { echo "missing: $f"; status=1; }
done
exit $status
SH
chmod +x check-links.sh
bruno; at '2026-09-19T11:00:00-03:00'; git add check-links.sh; git commit -qm 'Add a check for links to missing files'
git init -q --bare ~/remotes/site.git
git remote add origin ~/remotes/site.git
git push -q -u origin main 2>/dev/null
me

# Ana's ticket #34: the menu shows which items contain allergens.
git switch -q -c 34-allergens
mkdir -p images && printf 'PNG' > images/allergens.png
printf '<p><img src="images/allergens.png" alt="Allergens: gluten, milk, eggs"></p>\n' >> menu.html

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
