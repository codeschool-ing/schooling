#!/usr/bin/env bash
# The terminal sessions quoted in lesson 30 of go, as a script that produces them.
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
# lesson 4 showed and this one does not repeat. Nothing in the output varies
# between runs of the same binary; the addresses in the two panics are the
# ones this run printed.
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
mod() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

# --- before -------------------------------------------------------------------
mod generics
put generics/main.go <<'EOF'
package main

import "fmt"

func SumInts(xs []int) int {
	var total int
	for _, x := range xs {
		total += x
	}
	return total
}

func SumFloats(xs []float64) float64 {
	var total float64
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(SumInts([]int{3, 4, 5}))
	fmt.Println(SumFloats([]float64{1.5, 2.25}))
}
EOF

block twice
on generics 'go run .'
on generics 'diff <(sed -n 5,11p main.go) <(sed -n 13,19p main.go)'

block sort-doc
on generics 'go doc sort | grep -E "Ints|Float64s|Strings"'
on generics 'go doc sort.Ints'

mod generics-any
put generics-any/main.go <<'EOF'
package main

import "fmt"

func SumAny(xs []any) float64 {
	var total float64
	for _, x := range xs {
		switch v := x.(type) {
		case int:
			total += float64(v)
		case float64:
			total += v
		default:
			panic(fmt.Sprintf("SumAny: cannot add %T", v))
		}
	}
	return total
}

func main() {
	fmt.Println(SumAny([]any{3, 4, 5}))
	fmt.Println(SumAny([]any{1.5, 2.25}))

	var stock int64 = 7
	fmt.Println(SumAny([]any{3, stock}))
}
EOF

block any
on generics-any 'go vet && go run . 2>&1 | head -3'

mod generics-anyslice
put generics-anyslice/main.go <<'EOF'
package main

import "fmt"

func SumAny(xs []any) float64 {
	var total float64
	for _, x := range xs {
		switch v := x.(type) {
		case int:
			total += float64(v)
		case float64:
			total += v
		default:
			panic(fmt.Sprintf("SumAny: cannot add %T", v))
		}
	}
	return total
}

func main() {
	ages := []int{41, 7, 23}
	fmt.Println(SumAny(ages))

	boxed := make([]any, len(ages))
	for i, a := range ages {
		boxed[i] = a
	}
	total := SumAny(boxed)
	fmt.Printf("%v %T\n", total, total)
}
EOF

block anyslice
on generics-anyslice 'go run .'
quiet generics-anyslice "sed -i '/SumAny(ages))/d' main.go"
on generics-anyslice 'go run .'

mod generics-sort
put generics-sort/main.go <<'EOF'
package main

import "sort"

func main() {
	sort.Slice(42, func(i, j int) bool { return false })
}
EOF

block sort-slice
on generics-sort 'go doc sort.Slice | head -4'
on generics-sort 'go vet && go run .'

# --- what-they-solve --------------------------------------------------------
mod generics-sum
put generics-sum/main.go <<'EOF'
package main

import "fmt"

func Sum[T int | float64](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	ints := Sum([]int{3, 4, 5})
	floats := Sum([]float64{1.5, 2.25})
	fmt.Printf("%v %T\n", ints, ints)
	fmt.Printf("%v %T\n", floats, floats)
}
EOF

block sum
on generics-sum 'go run .'

mod generics-sumbad
put generics-sumbad/main.go <<'EOF'
package main

import "fmt"

func Sum[T int | float64](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	var stock int64 = 7
	fmt.Println(Sum([]int64{3, stock}))
	fmt.Println(Sum([]string{"a", "b"}))
}
EOF

block sumbad
on generics-sumbad 'go run .; echo $?'

mod generics-std
put generics-std/main.go <<'EOF'
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := []int{41, 7, 23}
	names := []string{"caio", "ana", "bia"}

	slices.Sort(ages)
	slices.Sort(names)
	fmt.Println(ages, names)

	fmt.Println(slices.Index(names, "bia"), slices.Contains(ages, 23))
	fmt.Println(slices.Max(ages), slices.Max(names))

	stock := map[string]int{"pear": 4, "fig": 0, "plum": 9}
	fmt.Println(slices.Sorted(maps.Keys(stock)))
}
EOF

block std
on generics-std 'go run .'
on generics-std 'go doc slices.Sort'
on generics-std 'go doc slices | wc -l'

block keys
on generics-std 'go doc maps.Keys | head -3'

# --- when-not ---------------------------------------------------------------
mod generics-when
put generics-when/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

type Celsius float64

func (c Celsius) String() string {
	return fmt.Sprintf("%.1fC", float64(c))
}

func ShowAll[T fmt.Stringer](items ...T) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func ShowEach(items ...fmt.Stringer) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func main() {
	room := Celsius(21.5)
	wait := 90 * time.Second
	ShowEach(room, wait)
	ShowAll(room, wait)
}
EOF

block when
on generics-when 'go run .'
quiet generics-when "sed -i 's/ShowAll(room, wait)/ShowAll(room, room+1)/' main.go"
on generics-when 'go run .'
