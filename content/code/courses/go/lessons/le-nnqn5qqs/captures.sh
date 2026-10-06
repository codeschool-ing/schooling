#!/usr/bin/env bash
# The terminal sessions quoted in lesson 37 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and a `go mod init` in each directory, which
# lesson 4 showed and this one does not repeat. In ~/stacks-release a git
# repository is created and its one commit made with a fixed author, committer
# and date (2026-10-06 10:00 -03:00), so that the revision `go version -m`
# prints is the same on every run; .gitignore names the three binaries built
# there. The reads of /usr/local/go/src and `go doc` are the Go 1.27.1 the lab
# installed.
#
# WHAT VARIES BETWEEN RUNS: in the `jobs` and `jobs-twice` blocks, the
# hexadecimal values inside the parentheses of the `panic(...)` and
# `main.price(...)` frames are heap addresses, which differ on every run; the
# lesson quotes one run of this script and says so. Nothing else varies.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on DIR 'command': what ana typed in ~/DIR, and what it printed.
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
put() { lab put "$1"; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# ---------------------------------------------------------------- reading-a-trace
lab fresh stacks
put stacks/main.go <<'EOF'
// Command stacks totals an order, and has a bug three calls deep.
package main

import "fmt"

type line struct {
	item string
	qty  int
}

var prices = map[string]int{"coffee": 450, "cake": 700}

// discount is a percentage, by quantity bought.
var discount = []int{0, 0, 5, 10}

func unitPrice(item string, qty int) int {
	return prices[item] * (100 - discount[qty]) / 100
}

func lineTotal(l line) int {
	return unitPrice(l.item, l.qty) * l.qty
}

func orderTotal(lines []line) int {
	total := 0
	for _, l := range lines {
		total += lineTotal(l)
	}
	return total
}

func main() {
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
EOF
quiet stacks 'go mod init example.com/stacks'

block trace
on stacks 'go build && ./stacks; echo $?'

block inline
on stacks "go build -gcflags=-m 2>&1 | grep 'inlining call'"

block noinline
on stacks "go build -gcflags=-l -o noinline . && ./noinline 2>&1 | grep -A1 '^main.unitPrice'"

block traceback-src
on stacks "grep -n -A12 'printFuncName(name)' \$(go env GOROOT)/src/runtime/traceback.go | head -13"

# ---------------------------------------------------------------- more-context
block gotraceback-doc
on stacks 'go doc runtime | sed -n 243,260p'

block gotraceback-none
on stacks 'GOTRACEBACK=none ./stacks; echo $?'

lab fresh stacks-jobs
put stacks-jobs/main.go <<'EOF'
// Command jobs prices three orders, and survives the one that has a bug.
package main

import (
	"log"
	"log/slog"
	"os"
	"runtime/debug"
)

type line struct {
	item string
	qty  int
}

var prices = map[string]int{"coffee": 450, "cake": 700}

// discount is a percentage, by quantity bought.
var discount = []int{0, 0, 5, 10}

func unitPrice(item string, qty int) int {
	return prices[item] * (100 - discount[qty]) / 100
}

func lineTotal(l line) int {
	return unitPrice(l.item, l.qty) * l.qty
}

func orderTotal(lines []line) int {
	total := 0
	for _, l := range lines {
		total += lineTotal(l)
	}
	return total
}

func price(id int, lines []line) {
	defer func() {
		if r := recover(); r != nil {
			slog.Error("order failed", "order", id, "panic", r)
			os.Stderr.Write(debug.Stack())
		}
	}()
	slog.Info("order priced", "order", id, "total", orderTotal(lines))
}

func main() {
	log.SetFlags(0) // slog's default output goes through log
	orders := [][]line{
		{{"coffee", 2}},
		{{"cake", 4}},
		{{"coffee", 1}, {"cake", 1}},
	}
	for i, o := range orders {
		price(i+1, o)
	}
}
EOF
quiet stacks-jobs 'go mod init example.com/jobs'

block jobs
on stacks-jobs 'go build && ./jobs; echo $?'

block jobs-twice
on stacks-jobs "for i in 1 2; do ./jobs 2>&1 | grep '^panic('; done"

block stack-doc
on stacks-jobs 'go doc runtime/debug.Stack'

block slog-doc
on stacks-jobs 'go doc log/slog | sed -n 30,33p'
on stacks-jobs 'go doc log/slog | sed -n 50,57p'

# ---------------------------------------------------------------- in-production
lab fresh stacks-release
put stacks-release/main.go <<'EOF'
// Command stacks totals an order, and says which build it is.
package main

import (
	"fmt"
	"runtime/debug"
)

type line struct {
	item string
	qty  int
}

var prices = map[string]int{"coffee": 450, "cake": 700}

// discount is a percentage, by quantity bought.
var discount = []int{0, 0, 5, 10}

func unitPrice(item string, qty int) int {
	return prices[item] * (100 - discount[qty]) / 100
}

func lineTotal(l line) int {
	return unitPrice(l.item, l.qty) * l.qty
}

func orderTotal(lines []line) int {
	total := 0
	for _, l := range lines {
		total += lineTotal(l)
	}
	return total
}

// version says which commit and which Go this binary was built from.
func version() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "unknown"
	}
	rev := "unknown"
	for _, s := range info.Settings {
		if s.Key == "vcs.revision" {
			rev = s.Value[:12]
		}
	}
	return info.Main.Version + " " + rev + " " + info.GoVersion
}

func main() {
	fmt.Println("stacks", version())
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
EOF
put stacks-release/.gitignore <<'EOF'
/stacks
/trim
/small
EOF
quiet stacks-release 'go mod init example.com/stacks'
quiet stacks-release 'git init -q && git add . && GIT_AUTHOR_DATE=2026-10-06T10:00:00-03:00 GIT_COMMITTER_DATE=2026-10-06T10:00:00-03:00 git -c user.name=Ana -c user.email=ana@example.com commit -q -m "Total an order"'

block release
on stacks-release 'git log --oneline'
on stacks-release 'go build && ./stacks 2>/dev/null; echo $?'
on stacks-release 'go version -m stacks'
on stacks-release 'go doc runtime/debug.BuildSetting | sed -n 27,32p'

block readbuildinfo-doc
on stacks-release 'go doc runtime/debug.ReadBuildInfo'

block trimpath
on stacks-release './stacks 2>&1 | tail -2'
on stacks-release 'go build -trimpath -o trim . && ./trim 2>&1 | tail -2'
on stacks-release 'go version -m trim | grep trimpath'
on stacks-release 'go help build | sed -n 167,171p'

block strip
on stacks-release 'go doc cmd/link | sed -n 118,120p'
on stacks-release 'go build -ldflags=-s -o small . && ./small 2>&1 | head -6'
on stacks-release 'wc -c stacks small'
on stacks-release 'go version -m small | head -3'
on stacks-release 'git show d569db795b44:main.go | sed -n 20p'
