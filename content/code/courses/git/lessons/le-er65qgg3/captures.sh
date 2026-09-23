#!/usr/bin/env bash
# The terminal session quoted in lesson 9 of git, as a script that produces it.
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
# a small ordering app's history kept the Git Flow way — main, develop, two
# feature branches, a release branch and a hotfix — built by the helper `c` and
# plain merges, with dates and authors set through GIT_AUTHOR_* and
# GIT_COMMITTER_*; only the three commands that read it are shown.
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

cd ~ && rm -rf ~/app
mkdir ~/app && cd ~/app && git init -q
bruno() { as 'Bruno Lima' 'bruno@example.com'; }
c() { git add -A && git commit -q -m "$1"; }
me; at '2026-06-01T09:00:00-03:00'
printf 'Padaria Sol ordering app\n' > README.md; c 'Start the ordering app'
git tag -a v1.0 -m 'First release' HEAD

# Git Flow: main holds releases, develop holds what is next.
git switch -q -c develop
at '2026-06-03T10:00:00-03:00'
git switch -q -c feature/basket develop
printf 'basket\n' > basket.txt; c 'Add a basket'
at '2026-06-04T10:00:00-03:00'
git switch -q develop; git merge -q --no-ff --no-edit feature/basket; git branch -q -d feature/basket
bruno; at '2026-06-05T11:00:00-03:00'
git switch -q -c feature/pickup develop
printf 'pickup\n' > pickup.txt; c 'Let customers choose a pickup time'
at '2026-06-08T11:00:00-03:00'
git switch -q develop; git merge -q --no-ff --no-edit feature/pickup; git branch -q -d feature/pickup
me; at '2026-06-09T09:00:00-03:00'
git switch -q -c release/1.1 develop
sed -i 's/app/app, version 1.1/' README.md; c 'Prepare release 1.1'
at '2026-06-10T09:00:00-03:00'
git switch -q main; git merge -q --no-ff --no-edit release/1.1; git tag -a v1.1 -m 'Release 1.1'
git switch -q develop; git merge -q --no-ff --no-edit release/1.1; git branch -q -d release/1.1
bruno; at '2026-06-11T16:00:00-03:00'
git switch -q -c hotfix/1.1.1 main
printf 'pickup, not before 06:00\n' > pickup.txt; c 'Refuse pickup times before we open'
at '2026-06-11T17:00:00-03:00'
git switch -q main; git merge -q --no-ff --no-edit hotfix/1.1.1; git tag -a v1.1.1 -m 'Release 1.1.1'
git switch -q develop; git merge -q --no-ff --no-edit hotfix/1.1.1; git branch -q -d hotfix/1.1.1
me

block gitflow
show 'git branch'
show 'git log --oneline --graph --all'
show 'git tag'
