#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. In ~/pointers-new the
# file is put twice, first with the line the compiler refuses and then with
# its fix, and `go mod edit -go=1.25` is typed to show what an older language
# version says about new(10).
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

lab fresh pointers
put pointers/main.go <<'EOF'
package main

import "fmt"

func double(n *int) {
	*n = *n * 2
}

func main() {
	x := 21
	p := &x
	fmt.Printf("%T\n", p)
	fmt.Println(*p, p == &x)

	*p = 30
	fmt.Println(x)

	double(&x)
	fmt.Println(x)
}
EOF
quiet pointers 'go mod init example.com/pointers'

block basics
on pointers 'go run .'

lab fresh pointers-nil
put pointers-nil/main.go <<'EOF'
package main

import "fmt"

func main() {
	var p *int
	fmt.Println(p == nil, p)
	fmt.Println(*p)
}
EOF
quiet pointers-nil 'go mod init example.com/nilptr'

block nil
on pointers-nil 'go run .'

lab fresh pointers-arith
put pointers-arith/main.go <<'EOF'
package main

import "fmt"

func main() {
	nums := [3]int{10, 20, 30}
	p := &nums[0]
	p++
	q := p + 1
	fmt.Println(*p, *q)
}
EOF
quiet pointers-arith 'go mod init example.com/arith'

block arith
on pointers-arith 'go run .'

lab fresh pointers-local
put pointers-local/main.go <<'EOF'
package main

import "fmt"

func newCounter() *int {
	n := 0
	return &n
}

func main() {
	a := newCounter()
	b := newCounter()
	*a++
	*a++
	*b++
	fmt.Println(*a, *b, a == b)
}
EOF
quiet pointers-local 'go mod init example.com/local'

block local
on pointers-local 'go run .'

lab fresh pointers-struct
put pointers-struct/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func win(p *Player) {
	p.Score++
}

func main() {
	ana := Player{Name: "Ana", Score: 10}
	win(&ana)
	fmt.Println(ana)

	bia := &Player{Name: "Bia"}
	win(bia)
	fmt.Println(bia, bia.Score, (*bia).Score)

	carla := new(Player)
	carla.Name = "Carla"
	fmt.Println(*carla)

	twin := &Player{Name: "Bia", Score: 1}
	fmt.Println(bia == twin, *bia == *twin)
}
EOF
quiet pointers-struct 'go mod init example.com/structs'

block structs
on pointers-struct 'go run .'

lab fresh pointers-new
put pointers-new/main.go <<'EOF'
package main

import "fmt"

type Options struct {
	Limit *int
}

func describe(o Options) string {
	if o.Limit == nil {
		return "no limit"
	}
	return fmt.Sprint("limit ", *o.Limit)
}

func main() {
	fmt.Println(describe(Options{}))
	fmt.Println(describe(Options{Limit: &10}))
}
EOF
quiet pointers-new 'go mod init example.com/options'

block new-refused
on pointers-new 'go run .'

put pointers-new/main.go <<'EOF'
package main

import "fmt"

type Options struct {
	Limit *int
}

func describe(o Options) string {
	if o.Limit == nil {
		return "no limit"
	}
	return fmt.Sprint("limit ", *o.Limit)
}

func main() {
	fmt.Println(describe(Options{}))
	fmt.Println(describe(Options{Limit: new(10)}))
}
EOF

block new-expr
on pointers-new 'go run .'
on pointers-new 'go mod edit -go=1.25 && go run .'

lab fresh pointers-append
put pointers-append/main.go <<'EOF'
package main

import "fmt"

func addTo(s *[]int, v int) {
	*s = append(*s, v)
}

func main() {
	nums := []int{1, 2, 3}
	addTo(&nums, 4)
	fmt.Println(nums, len(nums))
}
EOF
quiet pointers-append 'go mod init example.com/appendptr'

block append
on pointers-append 'go run .'

lab fresh pointers-map
put pointers-map/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	nums := []int{1, 2, 3}
	n := &nums[0]

	ages := map[string]int{"ana": 30}
	a := &ages["ana"]

	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	players["ana"].Score = 11

	fmt.Println(*n, *a)
}
EOF
quiet pointers-map 'go mod init example.com/mapaddr'

block map-refused
on pointers-map 'go run .'

lab fresh pointers-mapfix
put pointers-mapfix/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	p := players["ana"]
	p.Score++
	players["ana"] = p
	fmt.Println(players["ana"])

	byName := map[string]*Player{"ana": {Name: "Ana", Score: 10}}
	byName["ana"].Score++
	fmt.Println(*byName["ana"])
}
EOF
quiet pointers-mapfix 'go mod init example.com/mapfix'

block map-fix
on pointers-mapfix 'go run .'

lab fresh pointers-stale
put pointers-stale/main.go <<'EOF'
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	first := &nums[0]
	*first = 10
	fmt.Println(nums, len(nums), cap(nums))

	nums = append(nums, 4)
	*first = 100
	fmt.Println(nums, *first, first == &nums[0])
}
EOF
quiet pointers-stale 'go mod init example.com/stale'

block stale
on pointers-stale 'go run .'
