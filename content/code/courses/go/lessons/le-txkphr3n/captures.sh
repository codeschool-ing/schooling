#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows; ~/memory-grow and ~/memory-grow-kept are lesson
# 12's two growth programs, copied unchanged. NOTHING IN THE GARBAGE COLLECTOR'S
# OUTPUT REPEATS: the gctrace lines, the number of collections and the timings
# differ on every run, so the lesson quotes one run of this script and its
# prose reads the shape, never a digit it could not see. The heap sizes printed
# by ~/memory-keep are the same on every run.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo,
# on a virtual machine with four processors.

set -uo pipefail
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on DIR 'command': what ana typed in ~/DIR, and what it printed.
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
put() { lab put "$1"; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# --- stack-and-heap ---------------------------------------------------------
lab fresh memory
put memory/funcs.go <<'EOF'
package main

type point struct{ x, y int }

func sum() int {
	nums := [4]int{1, 2, 3, 4}
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func newPoint() *point {
	p := point{1, 2}
	return &p
}

func squares(n int) []int {
	s := make([]int, n)
	for i := range s {
		s[i] = i * i
	}
	return s
}

func count() int {
	buf := make([]int, 0, 8)
	buf = append(buf, 1, 2, 3)
	return len(buf)
}

func large() int {
	var table [200_000]int
	table[7] = 7
	return table[7]
}
EOF
put memory/main.go <<'EOF'
package main

import (
	"fmt"
	"testing"
)

var (
	keptPoint *point
	keptInts  []int
	n         int
)

func main() {
	fmt.Println("sum      ", testing.AllocsPerRun(100, func() { n = sum() }))
	fmt.Println("newPoint ", testing.AllocsPerRun(100, func() { keptPoint = newPoint() }))
	fmt.Println("squares  ", testing.AllocsPerRun(100, func() { keptInts = squares(100) }))
	fmt.Println("count    ", testing.AllocsPerRun(100, func() { n = count() }))
	fmt.Println("large    ", testing.AllocsPerRun(100, func() { n = large() }))
}
EOF
quiet memory 'go mod init example.com/memory'

block escape
on memory 'go build -gcflags="-m -l" . 2>&1 | grep funcs.go'

block stack-limit
on memory 'sed -n 8,11p /usr/local/go/src/cmd/compile/internal/ir/cfg.go'

block flags
on memory 'go tool compile -help 2>&1 | grep -E "^  -(l|m)\b"'

block allocs
on memory 'go run .'

lab fresh memory-grow
put memory-grow/main.go <<'EOF'
package main

import "fmt"

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
}
EOF
quiet memory-grow 'go mod init example.com/grow'
lab fresh memory-grow-kept
put memory-grow-kept/main.go <<'EOF'
package main

import "fmt"

var kept []int

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
	kept = s
}
EOF
quiet memory-grow-kept 'go mod init example.com/kept'

block grow
on memory-grow 'go build -gcflags="-m -l" . 2>&1 | grep append'
on memory-grow-kept 'go build -gcflags="-m -l" . 2>&1 | grep append'
on memory-grow 'grep -n "VariableMakeThreshold = " /usr/local/go/src/cmd/compile/internal/base/flag.go'

# --- the-collector ----------------------------------------------------------
lab fresh memory-gc
put memory-gc/main.go <<'EOF'
package main

import (
	"fmt"
	"runtime"
)

var live [][]byte
var last []byte

func main() {
	for range 80 {
		live = append(live, make([]byte, 100_000))
	}
	for range 50_000 {
		b := make([]byte, 10_000)
		for i := range b {
			b[i] = byte(i)
		}
		last = b
	}
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Printf("%d collections, %d MB allocated, heap at most %d MB\n",
		m.NumGC, m.TotalAlloc>>20, m.HeapSys>>20)
}
EOF
quiet memory-gc 'go mod init example.com/gc'

block mgc
on memory-gc 'sed -n 7,10p /usr/local/go/src/runtime/mgc.go'

block greentea
on memory-gc 'grep -n "GreenTeaGC" /usr/local/go/src/internal/buildcfg/exp.go'
on memory-gc 'sed -n 5,10p /usr/local/go/src/runtime/mgcmark_greenteagc.go'

block gctrace
on memory-gc 'go build -o gc .'
on memory-gc 'GODEBUG=gctrace=1 ./gc 2>&1 | sed -n "1,4p;\$p"'

block gctrace-doc
on memory-gc 'go doc runtime | grep -A 9 "where the fields are" | head -10'

block gogc-doc
on memory-gc 'go doc runtime | grep -A 5 "The GOGC variable"'

block gogc
on memory-gc 'for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./gc)"; done'

# --- limits -----------------------------------------------------------------
block memlimit-doc
on memory-gc 'go doc runtime | grep -A 11 "The GOMEMLIMIT variable"'

block memlimit
on memory-gc 'GOGC=off GOMEMLIMIT=64MiB ./gc'
on memory-gc 'time ./gc'
on memory-gc 'time GOMEMLIMIT=4MiB ./gc'

lab fresh memory-keep
put memory-keep/main.go <<'EOF'
package main

import (
	"fmt"
	"runtime"
	"slices"
	"strings"
)

// heapMB collects, then reports what the heap still holds.
func heapMB() uint64 {
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.HeapAlloc >> 20
}

// load stands in for reading a 64 MB file into memory.
func load() []byte {
	return make([]byte, 64<<20)
}

var header []byte
var name string

func main() {
	fmt.Printf("at start              %2d MB\n", heapMB())

	header = load()[:16]
	fmt.Printf("16 bytes kept         %2d MB\n", heapMB())
	header = slices.Clone(header)
	fmt.Printf("after slices.Clone    %2d MB\n", heapMB())

	name = string(load())[:16]
	fmt.Printf("16-byte substring     %2d MB\n", heapMB())
	name = strings.Clone(name)
	fmt.Printf("after strings.Clone   %2d MB\n", heapMB())
}
EOF
quiet memory-keep 'go mod init example.com/keep'

block keep
on memory-keep 'go run .'

block clone-doc
on memory-keep 'go doc strings.Clone'
on memory-keep 'go doc slices.Clone'
