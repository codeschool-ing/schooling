#!/usr/bin/env bash
# The terminal sessions quoted in this lesson, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. What the prose quotes
# was copied from running this, so the next person can run it against a newer
# Git and see what moved. It is the `.tape` of `linux-terminal`, for a subject
# whose screens are all lines of text.
#
#   sudo useradd -m -s /bin/bash ana     # once, on a throwaway machine
#   sudo -u ana -i bash /path/to/captures.sh
#
# It must start from an account that has never configured Git: the first scene
# is what Git says when nobody has. It deletes ~/.gitconfig, ~/report, ~/notes
# and ~/copy before it begins, which is why it wants a throwaway account.
#
# What is STAGED rather than typed, and not shown in the lesson: the files the
# scenes need, and the dates on the history in `what-a-history-is`, set with
# GIT_AUTHOR_DATE and GIT_COMMITTER_DATE so that three days of work do not
# happen in one second. Every line after a prompt is what Git printed.
#
# Recorded with git 2.43.0 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd ~ && rm -rf ~/.gitconfig ~/report ~/notes ~/copy ~/first

# Print the prompt and the command the way the lesson shows them, then run it.
show() {
  printf 'ana@vm:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$*"
  eval "$*" 2>&1 || true
}
scene() { printf '\n===== %s =====\n' "$1"; }

# ---------------------------------------------------------------- before-the-first-commit
scene 'before-the-first-commit: nobody has told Git anything'
show 'git --version'
show 'mkdir first && cd first'
show 'git init'
show "echo 'first line' > notes.txt"
show 'git add notes.txt'
show 'git commit -m "Start the notes"'

scene 'before-the-first-commit: telling it'
cd ~ && rm -rf ~/first
show 'git config --global user.name "Ana Souza"'
show 'git config --global user.email "ana@example.com"'
show 'git config --global init.defaultBranch main'
show 'git config --global core.editor nano'
show 'git config --global --list'
show 'cat ~/.gitconfig'

# ---------------------------------------------------------------- a-folder-of-copies
scene 'a-folder-of-copies'
mkdir ~/report && cd ~/report
cat > report.txt <<'T'
Quarterly report
Sales rose 4% against the last quarter.
The north region missed its target.
T
cp report.txt report-v2.txt
sed -i 's/4%/6%/' report-v2.txt
cp report-v2.txt report-v2-final.txt
printf 'Costs are flat.\n' >> report-v2-final.txt
cp report-v2-final.txt report-v2-final-bruno.txt
sed -i 's/missed its target/missed its target by 2%/' report-v2-final-bruno.txt
cp report-v2-final.txt report-FINAL.txt
sed -i 's/6%/5%/' report-FINAL.txt
touch -d '2026-09-01 09:12' report.txt
touch -d '2026-09-03 17:40' report-v2.txt
touch -d '2026-09-08 11:05' report-v2-final.txt
touch -d '2026-09-08 15:22' report-v2-final-bruno.txt
touch -d '2026-09-09 08:47' report-FINAL.txt
show 'ls -l'
show 'diff report-v2-final.txt report-FINAL.txt'
show 'diff report-v2-final.txt report-v2-final-bruno.txt'

# ---------------------------------------------------------------- what-a-history-is
scene 'what-a-history-is'
mkdir ~/notes && cd ~/notes && git init -q
commit() { # date, author name, author email, message
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" \
  GIT_AUTHOR_NAME="$2" GIT_AUTHOR_EMAIL="$3" \
  GIT_COMMITTER_NAME="$2" GIT_COMMITTER_EMAIL="$3" \
    git commit -q -m "$4"
}
cp ~/report/report.txt . && git add report.txt
commit '2026-09-01T09:12:00-03:00' 'Ana Souza' 'ana@example.com' 'Start the quarterly report'
sed -i 's/4%/6%/' report.txt && printf 'Costs are flat.\n' >> report.txt && git add report.txt
commit '2026-09-03T17:40:00-03:00' 'Ana Souza' 'ana@example.com' 'Use the corrected sales figure from finance'
sed -i 's/missed its target/missed its target by 2%/' report.txt
printf 'Region,Target,Actual\nNorth,100,98\nSouth,100,107\n' > regions.csv
git add report.txt regions.csv
commit '2026-09-08T15:22:00-03:00' 'Bruno Lima' 'bruno@example.com' 'Say by how much the north missed, and add the table it comes from'
sed -i 's/^Quarterly report$/Quarterly report, third quarter/' report.txt && git add report.txt
commit '2026-09-09T08:47:00-03:00' 'Ana Souza' 'ana@example.com' 'Name the quarter in the title'
show 'git log --oneline'
show 'git log -1'
show 'git log -1 --stat HEAD~1'
show 'git cat-file -p HEAD'
show 'git cat-file -p HEAD~1^{tree}'
show 'git cat-file -p HEAD^{tree}'

# ---------------------------------------------------------------- where-the-history-lives
scene 'where-the-history-lives'
cd ~
show 'git clone ~/notes ~/copy'
show 'rm -rf ~/notes'
show 'cd ~/copy'
cd ~/copy
show 'git log --oneline'
