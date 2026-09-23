#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of git, as a script that produces them.
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
# and authors set through GIT_AUTHOR_* and GIT_COMMITTER_*; a second
# repository with the same week's commits under careless messages; the
# commits whose messages the lesson reads, made with `git commit -F -` where
# a person would use the editor; `git add -p` run under `script` with its two
# answers typed a second apart, as a person reads and answers; and
# GIT_SEQUENCE_EDITOR=: for the autosquash rebase, which accepts the plan Git
# proposes unchanged; colour switched off.
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

cd ~ && rm -rf ~/before
git config --global color.ui never
# A command in a terminal, with answers typed after each prompt appears.
typed() {
  local answers="$1"; shift
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  ( for a in $answers; do sleep 1; printf '%s\n' "$a"; done ) | script -qec "$*" /dev/null || true
}

# The same week, messaged the way people do when nobody asks them not to.
mkdir ~/before && cd ~/before && git init -q
n=0
for m in 'first' 'update' 'changes' 'fix' 'wip' 'fixed stuff' 'asdf' 'more changes' 'final'; do
  n=$((n+1)); printf '%s\n' "$n" > f.txt; at "2026-09-1$((n % 5 + 4))T09:0${n}:00-03:00"; git add f.txt; git commit -qm "$m"
done
block bad-log
show 'git log --oneline'
cd ~/site
block good-log
show 'git log --oneline'

block body
at '2026-09-21T09:00:00-03:00'
sed -i 's/half past five/half past six/' index.html
git commit -qa -F - <<'MSG'
Open at half past six from October to March

The first bus from the station now arrives at 06:20, so customers
waiting at half past five were standing outside for nearly an hour.
Summer hours stay as they are.
MSG
show 'git log -1'

block conventional
git tag -a v1.0 -m 'The site as it went live' HEAD
at '2026-09-21T10:00:00-03:00'; sed -i 's/2.50/2.60/' menu.html; git commit -qam 'fix(menu): show the new price of cheese rolls'
at '2026-09-21T10:30:00-03:00'; printf '<p>Carrot cake, 3.00</p>\n' >> menu.html; git commit -qam 'feat(menu): add carrot cake'
at '2026-09-21T11:00:00-03:00'; printf 'How to add an item: one line per item in menu.html.\n' > README.md; git add README.md; git commit -qm 'docs: explain how to add a menu item'
at '2026-09-21T11:30:00-03:00'; printf '<form><label>Pickup time <input name="pickup" required></label></form>\n' > order.html; git add order.html
git commit -q -F - <<'MSG'
feat(order)!: require a pickup time for every order

The phone line used to accept orders with no time, and nobody knew
when to bake them.

BREAKING CHANGE: an order sent without a pickup time is refused.
MSG
show 'git log --oneline v1.0..HEAD'
show 'git log --oneline --grep="^feat" v1.0..HEAD'
show 'git log -1 --format=%B'

block add-p
at '2026-09-21T14:00:00-03:00'
sed -i 's/half past six/half past six, Monday to Saturday/' index.html
sed -i 's/French bread, 0.90/French bread, 0.95/' menu.html
show 'git diff --stat'
typed 'y n' 'git add -p'
show 'git commit -qm "fix(home): say which days we open"'
show 'git status --short'
git restore menu.html

block fixup
at '2026-09-21T15:00:00-03:00'
printf '<p>Seasonal cakes: ask at the counter.</p>\n' >> menu.html
git commit -qam 'feat(menu): mention seasonal cakes'
at '2026-09-21T15:20:00-03:00'
printf 'h1 { color: darkorange; }\np { line-height: 1.5; }\n' > style.css
git commit -qam 'style: give paragraphs more room'
at '2026-09-21T15:40:00-03:00'
sed -i 's/ask at the counter/ask at the counter!/' menu.html
show 'git commit -qa --fixup HEAD~1'
show 'git log --oneline -3'
export GIT_SEQUENCE_EDITOR=:
show 'git rebase -q -i --autosquash HEAD~3'
show 'git log --oneline -2'
