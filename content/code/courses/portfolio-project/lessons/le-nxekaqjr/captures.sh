#!/usr/bin/env bash
# Lesson 1 of portfolio-project: the student's own computer, before the first
# command of the course.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
# laptop is Ubuntu 24.04 with git, OpenSSH and Python 3 from Ubuntu's packages,
# and ana is an account on it that has never used git: no ~/.gitconfig and no
# ~/project. A line that starts with ana@laptop is what she typed; every line
# after it is what the command printed.
#
#   sudo -u ana -i bash /path/to/captures.sh      # on laptop, as a fresh ana
#
# laptop is a container on the computer that recorded the course. Nothing this
# lesson shows depends on that.
#
# Recorded on Ubuntu 24.04 with git 2.43, OpenSSH 9.6 and Python 3.12,
# TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat COLUMNS=100
# on DIR 'command': what ana typed at her prompt in DIR (relative to her home,
# "~" for the home itself), and everything it printed.
on() {
  local d=$1; shift
  local shown=$([ "$d" = "~" ] && echo "~" || echo "~/$d")
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd $HOME/$d")
  printf 'ana@laptop:%s$ %s\n' "$shown" "$*"
  ($cd && bash -c "$*") 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

rm -rf ~/project ~/.gitconfig

block versions
on '~' 'git --version'
on '~' 'ssh -V'
on '~' 'python3 --version'

block nobody
on '~' 'mkdir project && cd project && git init -q && echo "# project" > README.md'
on project 'git add README.md && git commit -m "Say what the project is for"'
# The three lines of the identity block, typed but shown in the other section.
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main
block master
on project 'git commit -q -m "Say what the project is for" && git branch --show-current'
on project 'git branch -m main && git branch --show-current'

rm -rf ~/project ~/.gitconfig
block identity
on '~' 'git config --global user.name "Ana Lima"'
on '~' 'git config --global user.email ana@example.org'
on '~' 'git config --global init.defaultBranch main'
on '~' 'git config --global --list'
on '~' 'mkdir project && cd project && git init && echo "# project" > README.md'
on project 'git add README.md && git commit -q -m "Say what the project is for" && git log --oneline'
