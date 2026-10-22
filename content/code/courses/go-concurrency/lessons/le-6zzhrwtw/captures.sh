#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of go-concurrency, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# THE PROGRAMS ARE THE LESSON'S OWN. Each file below is taken out of the
# section that shows it, by `lab.sh fence`, so the program that ran is the one
# the student reads.
# What is STAGED rather than typed: those files, written into ~/files, and a
# `go mod init` there. The timings in "buffered" differ on every run; the
# lesson quotes one run of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64 and
# gcc 13.3.0, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh files
show files.md files notes.go
show directories.md files tree.go
show bufio.md files buffered.go
show bufio.md files lines.go
quiet files 'go mod init example.com/files'

block notes
on files 'go run notes.go'
on files 'ls -l notes.txt'
on files 'umask'

block tree
on files 'go run tree.go'

block buffered
on files 'go run buffered.go'
on files 'wc -c plain.txt buffered.txt forgot.txt'
on files "tail -c 15 forgot.txt; echo '<- end of file'"

block lines
on files 'go run lines.go plain.txt'
on files "head -c 100000 /dev/zero | tr '\\0' x > long.txt; echo >> long.txt"
on files 'cat plain.txt long.txt > mixed.txt'
on files 'go run lines.go mixed.txt'
on files 'go run lines.go mixed.txt 1048576'
