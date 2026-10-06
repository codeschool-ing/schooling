#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of go, as a script that produces them.
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
# lesson 4 showed and this one does not repeat. THE ORDER IN WHICH A MAP IS
# WALKED IS CHOSEN AT RANDOM ON EVERY RUN, which is the point of section 03:
# the blocks order-run and small-run print something different each time, and
# the lesson quotes one run of this script.
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

# --- maps -------------------------------------------------------------------
lab fresh maps
put maps/main.go <<'EOF'
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31,
		"bia": 27,
	}
	fmt.Println(ages, len(ages))

	ages["caio"] = 45
	ages["ana"] = 32
	fmt.Println(ages, len(ages))

	delete(ages, "bia")
	delete(ages, "zeca")
	fmt.Println(ages, len(ages))

	stock := make(map[string]int)
	stock["pear"] = 3
	fmt.Println(stock, len(stock))
}
EOF
quiet maps 'go mod init example.com/maps'

block basics
on maps 'go run .'

lab fresh maps-nil
put maps-nil/main.go <<'EOF'
package main

import "fmt"

func main() {
	var prices map[string]int
	fmt.Println(prices["pear"], len(prices), prices == nil)

	prices["pear"] = 3
	fmt.Println("this line is never reached")
}
EOF
quiet maps-nil 'go mod init example.com/nil'

block nil
on maps-nil 'go run .'

lab fresh maps-key
put maps-key/main.go <<'EOF'
package main

import "fmt"

func main() {
	seen := map[[]byte]bool{}
	a := map[string]int{"x": 1}
	b := map[string]int{"x": 1}
	fmt.Println(seen, a == b)
}
EOF
quiet maps-key 'go mod init example.com/key'

block key
on maps-key 'go run .'

lab fresh maps-dup
put maps-dup/main.go <<'EOF'
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31,
		"bia": 27,
		"ana": 32,
	}
	fmt.Println(ages)
}
EOF
quiet maps-dup 'go mod init example.com/dup'

block dup
on maps-dup 'go run .'

# --- comma-ok ---------------------------------------------------------------
lab fresh maps-ok
put maps-ok/main.go <<'EOF'
package main

import "fmt"

func main() {
	stock := map[string]int{"apple": 0, "pear": 3}
	fmt.Println(stock["pear"], stock["apple"], stock["kiwi"])

	n, ok := stock["apple"]
	fmt.Println(n, ok)
	n, ok = stock["kiwi"]
	fmt.Println(n, ok)

	if _, ok := stock["kiwi"]; !ok {
		fmt.Println("kiwi is not on the list at all")
	}
}
EOF
quiet maps-ok 'go mod init example.com/ok'

block ok
on maps-ok 'go run .'

lab fresh maps-count
put maps-count/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

func main() {
	words := strings.Fields("the cat saw the dog and the dog saw the cat run")
	counts := map[string]int{}
	for i := 0; i < len(words); i++ {
		counts[words[i]]++
	}
	fmt.Println(counts)

	names := []string{"ana", "bruno", "alice", "caio", "bia"}
	byInitial := map[string][]string{}
	for i := 0; i < len(names); i++ {
		first := names[i][:1]
		byInitial[first] = append(byInitial[first], names[i])
	}
	fmt.Println(byInitial)
}
EOF
quiet maps-count 'go mod init example.com/count'

block count
on maps-count 'go run .'

# --- unordered --------------------------------------------------------------
lab fresh maps-order
put maps-order/main.go <<'EOF'
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	var walked []string
	for name, age := range ages {
		walked = append(walked, fmt.Sprint(name, ":", age))
	}
	fmt.Println(walked)
	fmt.Println(ages)
}
EOF
quiet maps-order 'go mod init example.com/order'

block order-run
on maps-order 'go run .'
on maps-order 'go run .'

lab fresh maps-sorted
put maps-sorted/main.go <<'EOF'
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	names := slices.Sorted(maps.Keys(ages))
	var walked []string
	for i := 0; i < len(names); i++ {
		walked = append(walked, fmt.Sprint(names[i], ":", ages[names[i]]))
	}
	fmt.Println(walked)
}
EOF
quiet maps-sorted 'go mod init example.com/sorted'

block sorted
on maps-sorted 'go run .'

lab fresh maps-small
put maps-small/main.go <<'EOF'
package main

import "fmt"

func main() {
	steps := map[string]int{"build": 1, "test": 2, "push": 3, "deploy": 4}
	var walked []string
	for step := range steps {
		walked = append(walked, step)
	}
	fmt.Println(walked)
}
EOF
quiet maps-small 'go mod init example.com/small'

block small-run
on maps-small 'go build && for i in 1 2 3 4 5 6; do ./small; done'

block keys-doc
on maps-small 'go doc maps.Keys'
