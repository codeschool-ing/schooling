#!/usr/bin/env bash
# The terminal sessions quoted in lesson 31 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows; a `go mod init` in each directory, which lesson 4
# showed and this one does not repeat; and the one-line edits made with `sed`
# between two runs of the same directory, which the lesson describes in its
# prose. Nothing in the output varies between runs.
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

# --- functions --------------------------------------------------------------
mod generic2
put generic2/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func Map[T, U any](xs []T, f func(T) U) []U {
	out := make([]U, 0, len(xs))
	for _, x := range xs {
		out = append(out, f(x))
	}
	return out
}

func Make[T any](n int) []T {
	return make([]T, n)
}

func main() {
	ages := []int{41, 7, 23}
	labels := Map(ages, strconv.Itoa)
	fmt.Printf("%q %T\n", labels, labels)

	halves := Map(ages, func(n int) float64 { return float64(n) / 2 })
	fmt.Println(halves)

	names := Make[string](2)
	fmt.Printf("%q %T\n", names, names)

	toText := Map[int, string]
	fmt.Printf("%T\n", toText)
}
EOF

block map
on generic2 'go run .'

mod generic2-infer
put generic2-infer/main.go <<'EOF'
package main

import "fmt"

func Map[T, U any](xs []T, f func(T) U) []U {
	out := make([]U, 0, len(xs))
	for _, x := range xs {
		out = append(out, f(x))
	}
	return out
}

func Make[T any](n int) []T {
	return make([]T, n)
}

func main() {
	names := Make(2)
	var labels []string = Make(2)
	toText := Map
	fmt.Println(names, labels, toText)
}
EOF

block infer
on generic2-infer 'go run .'

mod generic2-mix
put generic2-mix/main.go <<'EOF'
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	top := Biggest(3, 2.5)
	fmt.Printf("%v %T\n", top, top)

	var count int = 3
	var price float64 = 2.5
	fmt.Println(Biggest(count, price))
}
EOF

block mix
on generic2-mix 'go run .'
quiet generic2-mix "sed -i 's/Biggest(count, price)/Biggest(float64(count), price)/' main.go"
on generic2-mix 'go run .'

# --- constraints ------------------------------------------------------------
mod generic2-index
put generic2-index/main.go <<'EOF'
package main

import "fmt"

func Index[T any](xs []T, v T) int {
	for i, x := range xs {
		if x == v {
			return i
		}
	}
	return -1
}

func main() {
	fmt.Println(Index([]string{"ana", "bia", "caio"}, "bia"))
}
EOF

block index
on generic2-index 'go run .'
quiet generic2-index "sed -i 's/Index\[T any\]/Index[T comparable]/' main.go"
on generic2-index 'go run .'

block comparable-doc
on generic2-index 'go doc builtin.comparable'

mod generic2-celsius
put generic2-celsius/main.go <<'EOF'
package main

import "fmt"

type Celsius float64

func Sum[T int | float64](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	week := []Celsius{20.5, 22, 19.5}
	fmt.Println(Sum(week))
}
EOF

block celsius
on generic2-celsius 'go run .'

mod generic2-number
put generic2-number/main.go <<'EOF'
package main

import (
	"fmt"
	"slices"
)

type Number interface {
	~int | ~float64
}

func Sum[T Number](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

type Celsius float64

func main() {
	week := []Celsius{20.5, 22, 19.5}
	total := Sum(week)
	fmt.Printf("%v %T\n", total, total)
	fmt.Println(Sum([]int{3, 4, 5}))

	slices.Sort(week)
	fmt.Println(week, slices.Max(week))
}
EOF

block number
on generic2-number 'go run .'

mod generic2-astype
put generic2-astype/main.go <<'EOF'
package main

import "fmt"

type Number interface {
	~int | ~float64
}

func main() {
	var n Number = 3
	fmt.Println(n)
}
EOF

block astype
on generic2-astype 'go run .'

block ordered
on generic2-number 'go doc cmp.Ordered | head -7'

mod generic2-clone
put generic2-clone/main.go <<'EOF'
package main

import (
	"fmt"
	"slices"
)

type Names []string

func CloneFlat[E any](s []E) []E {
	return append([]E(nil), s...)
}

func main() {
	team := Names{"ana", "bia"}
	a := slices.Clone(team)
	b := CloneFlat(team)
	fmt.Printf("%T %T\n", a, b)
}
EOF

block clone
on generic2-clone 'go doc slices.Clone | head -3'
on generic2-clone 'go run .'

# --- types ------------------------------------------------------------------
mod generic2-stack
put generic2-stack/main.go <<'EOF'
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Pop() (T, bool) {
	var zero T
	if len(s.items) == 0 {
		return zero, false
	}
	top := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return top, true
}

func main() {
	var words Stack[string]
	words.Push("first")
	words.Push("second")
	fmt.Println(words.Pop())
	fmt.Println(words.Pop())
	last, ok := words.Pop()
	fmt.Printf("%q %v\n", last, ok)

	nums := &Stack[int]{}
	nums.Push(42)
	fmt.Printf("%T %v\n", nums, nums.items)
}
EOF

block stack
on generic2-stack 'go run .'

mod generic2-stackbad
put generic2-stackbad/main.go <<'EOF'
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func main() {
	var s Stack
	words := Stack[string]{}
	words.Push(3)
	var nums Stack[int] = words
	fmt.Println(s, nums)
}
EOF

block stackbad
on generic2-stackbad 'go run .'

mod generic2-contains
put generic2-contains/main.go <<'EOF'
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Contains(v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}

func main() {
	var s Stack[string]
	s.Push("ana")
	fmt.Println(s.Contains("ana"))
}
EOF

block contains
on generic2-contains 'go run .'

mod generic2-contains2
put generic2-contains2/main.go <<'EOF'
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func Contains[T comparable](s *Stack[T], v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}

func main() {
	var s Stack[string]
	s.Push("ana")
	fmt.Println(Contains(&s, "ana"), Contains(&s, "bia"))
}
EOF

block contains2
on generic2-contains2 'go run .'

mod generic2-method
put generic2-method/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Map[U any](f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.Push(f(v))
	}
	return out
}

func main() {
	ages := &Stack[int]{}
	ages.Push(41)
	ages.Push(7)
	labels := ages.Map(strconv.Itoa)
	fmt.Printf("%q %T\n", labels.items, labels)
}
EOF

block method
on generic2-method 'go run .'
on generic2-method 'go mod edit -go=1.26 && go run .'
quiet generic2-method 'go mod edit -go=1.27.1'

mod generic2-iface
put generic2-iface/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Map[U any](f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.Push(f(v))
	}
	return out
}

type Mapper interface {
	Map[U any](f func(int) U) *Stack[U]
}

type TextMapper interface {
	Map(f func(int) string) *Stack[string]
}

func main() {
	var m TextMapper = &Stack[int]{}
	fmt.Println(m.Map(strconv.Itoa))
}
EOF

block iface
on generic2-iface 'go run .'
