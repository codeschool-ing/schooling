#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and the `go mod init` in each directory, which
# lesson 4 already showed. The panic's goroutine number and offsets are those
# of one run; the lesson quotes one run of this script.
#
# The programs that handle accents, flags and combining marks write them with
# escapes (\u00e9, \U0001F1E7) and print them with %+q or % x, so that every
# character the lesson quotes from a terminal is one the page can draw.
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

# --- booleans -------------------------------------------------------------

lab fresh runes-truthy
put runes-truthy/main.go <<'EOF'
package main

import "fmt"

func main() {
	count := 3
	name := "Ana"
	if count {
		fmt.Println("there is work to do")
	}
	if name {
		fmt.Println("hello,", name)
	}
	ready := bool(count)
	fmt.Println(!count, ready)
}
EOF
quiet runes-truthy 'go mod init example.com/truthy'

block truthy
on runes-truthy 'go run .; echo $?'

lab fresh runes-bool
put runes-bool/main.go <<'EOF'
package main

import "fmt"

func main() {
	count := 3
	name := "Ana"
	if count > 0 {
		fmt.Println("there is work to do")
	}
	if name != "" {
		fmt.Println("hello,", name)
	}

	tests, lint := true, false
	fmt.Println(tests && lint, tests || lint, !lint)
	fmt.Println(tests != lint, tests == lint)
	fmt.Printf("%t %v %T\n", tests, tests, tests)
}
EOF
quiet runes-bool 'go mod init example.com/bool'

block bool
on runes-bool 'go run .'

block doc-bool
on runes-bool 'go doc builtin.bool'

lab fresh runes-xor
put runes-xor/main.go <<'EOF'
package main

import "fmt"

func main() {
	tests, lint := true, false
	fmt.Println(tests ^ lint)
}
EOF
quiet runes-xor 'go mod init example.com/xor'

block xor
on runes-xor 'go run .'

lab fresh runes-short
put runes-short/main.go <<'EOF'
package main

import "fmt"

func main() {
	total, people := 120, 0

	if people > 0 && total/people > 50 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("the guard held")

	if total/people > 50 && people > 0 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("never printed")
}
EOF
quiet runes-short 'go mod init example.com/short'

block short
on runes-short 'go run .; echo $?'

# --- byte and rune --------------------------------------------------------

block doc-alias
on runes-short 'go doc builtin.byte'
on runes-short 'go doc builtin.rune'

lab fresh runes-num
put runes-num/main.go <<'EOF'
package main

import "fmt"

func main() {
	var b byte = 'A'
	r := 'A'
	fmt.Println(b, r)
	fmt.Printf("%T %T\n", b, r)
	fmt.Printf("%c %U %q\n", r, r, r)
	fmt.Println('a'-'A', 'A'+2)
	fmt.Printf("%c\n", 'A'+2)
}
EOF
quiet runes-num 'go mod init example.com/num'

block num
on runes-num 'go run .'

lab fresh runes-utf8
put runes-utf8/main.go <<'EOF'
package main

import "fmt"

func main() {
	e := 'é'
	fmt.Printf("%d %c %U\n", e, e, e)
	fmt.Println(len("e"), len("é"), len("€"), len("\U0001F642"))
	fmt.Printf("% x\n", "é")
	fmt.Printf("% x\n", "€")
}
EOF
quiet runes-utf8 'go mod init example.com/utf8'

block utf8
on runes-utf8 'go run .'

lab fresh runes-quotes
put runes-quotes/main.go <<'EOF'
package main

import "fmt"

func main() {
	var b byte = 'é'
	var euro byte = '€'
	pair := 'ab'
	fmt.Println(b, euro, pair)
}
EOF
quiet runes-quotes 'go mod init example.com/quotes'

block quotes
on runes-quotes 'go run .'

# --- characters -----------------------------------------------------------

lab fresh runes-cafe
put runes-cafe/main.go <<'EOF'
package main

import (
	"fmt"
	"unicode"
)

func main() {
	composed := "caf\u00e9"
	decomposed := "cafe\u0301"
	fmt.Println(composed == decomposed)
	fmt.Println(len(composed), len(decomposed))
	fmt.Printf("%+q\n%+q\n", composed, decomposed)
	fmt.Printf("% x\n% x\n", composed, decomposed)
	fmt.Println(unicode.IsLetter('\u0301'), unicode.IsMark('\u0301'))
}
EOF
quiet runes-cafe 'go mod init example.com/cafe'

block cafe
on runes-cafe 'go run .'

lab fresh runes-flag
put runes-flag/main.go <<'EOF'
package main

import "fmt"

func main() {
	brazil := "\U0001F1E7\U0001F1F7"
	fmt.Printf("%+q\n", brazil)
	fmt.Println(len(brazil))
	fmt.Printf("%U %U\n", '\U0001F1E7', '\U0001F1F7')
}
EOF
quiet runes-flag 'go mod init example.com/flag'

block flag
on runes-flag 'go run .'

block std
on runes-flag "go list std | grep '^unicode'"
on runes-flag 'go doc unicode.Version'
