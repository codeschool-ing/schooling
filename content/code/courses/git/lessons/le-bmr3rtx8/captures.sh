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
# What is STAGED rather than typed, and not shown in the lesson:
# lesson 3's week of the bakery's site, rebuilt by the helper `c` with dates
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; the files each
# scene needs, written with printf, head and dd between the commands shown;
# the shared-styles repository the submodule points at, a bare one in
# ~/remotes with one commit; and protocol.file.allow=always, because the
# stand-in remotes are local folders and Git refuses a local submodule
# address by default. Needs git-lfs installed (3.4.1 here).
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

cd ~ && rm -rf ~/remotes ~/copy ~/photos
git config --global protocol.file.allow always
cd ~/site

block before-ignore
mkdir -p node_modules/lightbox && printf 'x\n' > node_modules/lightbox/index.js
printf 'x\n' > .DS_Store; printf 'x\n' > debug.log; printf 'call the supplier\n' > notes-private.txt
show 'git status --short'

block after-ignore
printf '# Other people'"'"'s code, which a package manager fetches again\nnode_modules/\n\n# Files the operating system or the tools leave behind\n.DS_Store\n*.log\n\n# Notes that are nobody else'"'"'s business\nnotes-private.txt\n' > .gitignore
show 'git status --short'
show 'git check-ignore -v debug.log node_modules/lightbox/index.js'

block gitignore-file
show 'cat .gitignore'
at '2026-09-21T09:00:00-03:00'
git add .gitignore && git commit -qm 'Ignore what nobody should commit'

block tracked
at '2026-09-21T09:10:00-03:00'
printf 'preview = on\n' > settings.local
git add settings.local && git commit -qm 'Add local settings'
printf 'settings.local\n' >> .gitignore
git commit -qam 'Ignore local settings'
printf 'preview = off\n' > settings.local
show 'git status --short'
show 'git rm --cached settings.local'
show 'git status --short'
show 'git commit -qm "Stop tracking local settings"'
show 'git status --short'

block secret
at '2026-09-21T10:00:00-03:00'
printf 'PAYMENT_KEY=sk_live_example_not_a_real_key\n' > .env
git add .env && git commit -qm 'Configure payments'
at '2026-09-21T10:05:00-03:00'
git rm -q --cached .env && printf '.env\n' >> .gitignore && git add .gitignore && git commit -qm 'Remove the payment key'
show 'git log --oneline -2'
show 'ls .env && git status --short'
show 'git show HEAD~1:.env'

block growth
at '2026-09-21T11:00:00-03:00'
show 'du -sh .git'
for i in 1 2 3; do head -c 1048576 /dev/urandom > photo.jpg; git add photo.jpg; git commit -qm "Photo of the shop front, take $i"; done
show 'du -h photo.jpg'
show 'du -sh .git'

block lfs
cd ~ && mkdir photos && cd photos && git init -q
show 'git lfs install'
show 'git lfs track "*.jpg"'
show 'cat .gitattributes'
head -c 1048576 /dev/zero | tr '\0' 'a' > front.jpg
at '2026-09-21T12:00:00-03:00'
show 'git add .gitattributes front.jpg'
show 'git commit -qm "Add the shop front photo"'
show 'git lfs ls-files'
show 'git show HEAD:front.jpg'

block submodule
cd ~ && mkdir -p remotes
git init -q --bare remotes/shared-styles.git
git clone -q remotes/shared-styles.git /tmp/ss-$$ 2>/dev/null; cd /tmp/ss-$$
at '2026-09-20T10:00:00-03:00'
printf ':root { --brand: darkorange; }\n' > brand.css; git add brand.css; git commit -qm 'Add the brand colour'; git push -q origin HEAD:main 2>/dev/null
cd ~ && rm -rf /tmp/ss-$$
git init -q --bare remotes/site.git
cd ~/site && git remote add origin ~/remotes/site.git
at '2026-09-21T13:00:00-03:00'
show 'git submodule add ~/remotes/shared-styles.git styles'
show 'cat .gitmodules'
show 'git status --short'
show 'git commit -qm "Use the shared brand styles"'
show 'git submodule status'
git push -q -u origin main 2>/dev/null

block submodule-clone
cd ~
show 'git clone -q ~/remotes/site.git copy && cd copy'
show 'ls styles'
show 'git submodule update --init'
show 'ls styles'
