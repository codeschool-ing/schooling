#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of go, as a script that produces them.
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
# lesson 4 showed and this lesson does not repeat. Nothing in this lesson
# varies between runs: the one map it walks is printed by fmt, which sorts it,
# or walked through a sorted slice of its keys.
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
module() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

# --- section for -----------------------------------------------------------------

module loops
put loops/main.go <<'EOF'
package main

import "fmt"

func main() {
	for i := 0; i < 3; i++ {
		fmt.Println("pass", i)
	}

	n := 100
	for n > 1 {
		n /= 3
	}
	fmt.Println("n is", n)

	tries := 0
	for {
		tries++
		if tries == 4 {
			break
		}
	}
	fmt.Println("tries:", tries)
}
EOF

block forms
on loops 'go run .'

module loops-scope
put loops-scope/main.go <<'EOF'
package main

import "fmt"

func main() {
	for i := 0; i < 3; i++ {
		fmt.Println("pass", i)
	}
	fmt.Println("done after", i)
}
EOF

block scope
on loops-scope 'go run .'

module loops-while
put loops-while/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 100
	while n > 1 {
		n /= 3
	}
	fmt.Println("n is", n)
}
EOF

block while
on loops-while 'go run .'

module loops-int
put loops-int/main.go <<'EOF'
package main

import "fmt"

func main() {
	for i := range 3 {
		fmt.Println("pass", i)
	}
	for range 2 {
		fmt.Println("again")
	}
}
EOF

block int
on loops-int 'go run .'
on loops-int 'go mod edit -go=1.21 && go run .'

# --- section range ---------------------------------------------------------------

module loops-range
put loops-range/main.go <<'EOF'
package main

import "fmt"

func main() {
	langs := []string{"Go", "C", "Python"}

	for i, lang := range langs {
		fmt.Println(i, lang)
	}

	for lang := range langs {
		fmt.Print(" ", lang)
	}
	fmt.Println()

	for _, lang := range langs {
		fmt.Print(" ", lang)
	}
	fmt.Println()
}
EOF

block range
on loops-range 'go run .'

module loops-copy
put loops-copy/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	team := []Player{{"Ana", 10}, {"Bia", 7}}

	for _, p := range team {
		p.Score += 5
	}
	fmt.Println(team)

	for i := range team {
		team[i].Score += 5
	}
	fmt.Println(team)
}
EOF

block copy
on loops-copy 'go run .'
on loops-copy 'go vet; echo $?'

module loops-once
put loops-once/main.go <<'EOF'
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	for _, n := range nums {
		nums = append(nums, n*10)
	}
	fmt.Println(nums)
}
EOF

block once
on loops-once 'go run .'

# --- section maps-and-strings ----------------------------------------------------

module loops-map
put loops-map/main.go <<'EOF'
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	stock := map[string]int{"apples": 3, "pears": 0, "plums": 7, "figs": 0}

	for fruit, n := range stock {
		if n == 0 {
			delete(stock, fruit)
		}
	}
	fmt.Println(stock)

	for _, fruit := range slices.Sorted(maps.Keys(stock)) {
		fmt.Println(fruit, stock[fruit])
	}

	total := 0
	for n := range maps.Values(stock) {
		total += n
	}
	fmt.Println("total", total)
}
EOF

block map
on loops-map 'go run .'
on loops-map 'go mod edit -go=1.22 && go run .'

module loops-string
put loops-string/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := "café\xff!"

	for i, r := range s {
		fmt.Printf("%d %U\n", i, r)
	}

	fmt.Println(len(s))
	for i := 0; i < len(s); i++ {
		fmt.Printf("%d %x\n", i, s[i])
	}
}
EOF

block string
on loops-string 'go run .'
on loops-string "go doc unicode/utf8.RuneError | grep 'RuneError ='"
