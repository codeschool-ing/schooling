#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of git, as a script that produces them.
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
# The files of the bakery's site are written by commands typed in the
# transcripts, printf and sed, where a person could equally use an editor.
#
# What is STAGED rather than typed: the date of each commit, set with
# GIT_AUTHOR_DATE and GIT_COMMITTER_DATE so that a morning's work is not one
# second.
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

cd ~ && rm -rf ~/site
me
at '2026-09-14T09:05:00-03:00'

block init
show 'mkdir site && cd site'
show 'git init'
show "printf '<h1>Padaria Sol</h1>\\n<p>Bread from six in the morning.</p>\\n' > index.html"
show 'ls -a'
show 'ls .git'

block untracked
show 'git status'

block staged
show 'git add index.html'
show 'git status'

block first-commit
show 'git commit -m "Add the home page"'
show 'git status'

# two unrelated changes in the working tree
at '2026-09-14T10:20:00-03:00'
block two-changes
show "sed -i 's/six in the morning/half past five/' index.html"
show "printf 'h1 { color: darkorange; }\\n' > style.css"
show 'git status'
show 'git add style.css'
show 'git status'
show 'git commit -m "Give the heading its colour"'

block edit-after-add
at '2026-09-14T11:40:00-03:00'
show 'git add index.html'
show "sed -i 's/half past five/half past five, every day/' index.html"
show 'git status'
show 'git diff'
show 'git diff --staged'
show 'git commit -m "Open half an hour earlier"'
show 'git status'

block commit-a
at '2026-09-14T14:10:00-03:00'
show "printf '<h1>Menu</h1>\\n<p>French bread, 0.80</p>\\n' > menu.html"
show 'git status --short'
show 'git commit -am "Open every day"'
show 'git status --short'

block rm-mv
at '2026-09-15T09:30:00-03:00'
show "printf 'Ask the supplier about rye flour\\n' > todo.txt"
show 'git add menu.html todo.txt && git commit -q -m "Add the menu and a to-do list"'
show 'mv style.css site.css'
show 'git status --short'
show 'mv site.css style.css'
show 'git mv style.css site.css'
show 'git status --short'
show 'git rm todo.txt'
show 'git status --short'
show 'git commit -m "Rename the stylesheet and drop the to-do list"'

block log
show 'git log --oneline'
