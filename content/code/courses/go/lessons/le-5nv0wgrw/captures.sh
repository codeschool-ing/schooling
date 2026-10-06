#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and the `go mod init` in each directory, run
# quietly because lesson 4 already showed what it prints. The benchmark
# timings in byvalue-cost differ on every run; the lesson quotes one run of
# this script, on a 4-core Intel Xeon at 2.10GHz.
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

lab fresh byvalue
put byvalue/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
	Last  [3]int
}

func double(n int) {
	n = n * 2
}

func win(p Player) {
	p.Score++
	p.Last[0] = 100
}

func main() {
	n := 21
	double(n)
	fmt.Println(n)

	ana := Player{Name: "Ana", Score: 10}
	win(ana)
	fmt.Println(ana)

	bia := ana
	bia.Name = "Bia"
	bia.Last[1] = 50
	fmt.Println(ana)
	fmt.Println(bia)
}
EOF
quiet byvalue 'go mod init example.com/byvalue'

block copies
on byvalue 'go run .'

lab fresh byvalue-return
put byvalue-return/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func win(p Player) Player {
	p.Score++
	return p
}

func main() {
	ana := Player{Name: "Ana", Score: 10}
	ana = win(ana)
	fmt.Println(ana)
}
EOF
quiet byvalue-return 'go mod init example.com/byvalue-return'

block return
on byvalue-return 'go run .'

lab fresh byvalue-sizes
put byvalue-sizes/main.go <<'EOF'
package main

import (
	"fmt"
	"unsafe"
)

type Player struct {
	Name  string
	Score int
}

func main() {
	var (
		s   []int
		m   map[string]int
		str string
		f   func()
		v   any
		c   chan int
	)
	fmt.Println("slice    ", unsafe.Sizeof(s))
	fmt.Println("map      ", unsafe.Sizeof(m))
	fmt.Println("string   ", unsafe.Sizeof(str))
	fmt.Println("func     ", unsafe.Sizeof(f))
	fmt.Println("interface", unsafe.Sizeof(v))
	fmt.Println("chan     ", unsafe.Sizeof(c))

	ana := Player{Name: "Ana", Score: 10}
	v = ana
	ana.Score = 99
	fmt.Println(v, ana)
}
EOF
quiet byvalue-sizes 'go mod init example.com/sizes'

block sizes
on byvalue-sizes 'go run .'

lab fresh byvalue-map
put byvalue-map/main.go <<'EOF'
package main

import "fmt"

func addKey(m map[string]int) {
	m["bia"] = 2
}

func replace(m map[string]int) {
	m = map[string]int{"carla": 3}
	fmt.Println("inside: ", m)
}

func main() {
	ages := map[string]int{"ana": 1}

	addKey(ages)
	fmt.Println("addKey: ", ages)

	replace(ages)
	fmt.Println("replace:", ages)
}
EOF
quiet byvalue-map 'go mod init example.com/maps'

block map
on byvalue-map 'go run .'

lab fresh byvalue-nil
put byvalue-nil/main.go <<'EOF'
package main

import "fmt"

func load(m map[string]int) {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
}

func main() {
	var ages map[string]int
	load(ages)
	fmt.Println(ages, len(ages), ages == nil)
	ages["bia"] = 2
}
EOF
quiet byvalue-nil 'go mod init example.com/nilmap'

block nil-map
on byvalue-nil 'go run .'

lab fresh byvalue-fix
put byvalue-fix/main.go <<'EOF'
package main

import "fmt"

func load(m map[string]int) map[string]int {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
	return m
}

func main() {
	var ages map[string]int
	ages = load(ages)
	ages["bia"] = 2
	fmt.Println(ages, len(ages), ages == nil)
}
EOF
quiet byvalue-fix 'go mod init example.com/nilmap'

block nil-map-fix
on byvalue-fix 'go run .'

lab fresh byvalue-cost
put byvalue-cost/main.go <<'EOF'
package main

import (
	"fmt"
	"testing"
	"unsafe"
)

type Point struct{ X, Y int }

type Record struct {
	ID     int
	Values [127]int
}

var big [1_000_000]int

//go:noinline
func viaPoint(p Point) int { return p.X }

//go:noinline
func viaRecord(r Record) int { return r.ID }

//go:noinline
func viaArray(a [1_000_000]int) int { return a[0] }

//go:noinline
func viaSlice(s []int) int { return s[0] }

func main() {
	var p Point
	var r Record
	s := big[:]
	fmt.Println(unsafe.Sizeof(p), unsafe.Sizeof(r), unsafe.Sizeof(big), unsafe.Sizeof(s))
	fmt.Println("Point ", testing.Benchmark(func(b *testing.B) {
		for b.Loop() {
			viaPoint(p)
		}
	}))
	fmt.Println("Record", testing.Benchmark(func(b *testing.B) {
		for b.Loop() {
			viaRecord(r)
		}
	}))
	fmt.Println("array ", testing.Benchmark(func(b *testing.B) {
		for b.Loop() {
			viaArray(big)
		}
	}))
	fmt.Println("slice ", testing.Benchmark(func(b *testing.B) {
		for b.Loop() {
			viaSlice(s)
		}
	}))
}
EOF
quiet byvalue-cost 'go mod init example.com/cost'

block cost
on byvalue-cost 'go run .'
