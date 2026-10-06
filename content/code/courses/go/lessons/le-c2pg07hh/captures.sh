#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and the `go mod init` of each directory, which
# lesson 4 already showed. A directory shown twice holds two versions of the
# same file: the second `put` replaces the first. The two counts of lines in
# /usr/local/go/src read the Go 1.27.1 source the lab installed.
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

# ---------------------------------------------------------------- break-continue
lab fresh flow
put flow/main.go <<'EOF'
// Command total adds up the numbers in a list of lines, up to the line "end".
package main

import (
	"fmt"
	"strconv"
)

func main() {
	lines := []string{"12", "", "7", "seven", "end", "40"}
	sum := 0
	for _, line := range lines {
		if line == "end" {
			break
		}
		n, err := strconv.Atoi(line)
		if err != nil {
			fmt.Printf("skipping %q\n", line)
			continue
		}
		sum += n
	}
	fmt.Println("sum:", sum)
}
EOF
quiet flow 'go mod init example.com/total'

block total
on flow 'go run .'

lab fresh flow-skip
put flow-skip/main.go <<'EOF'
package main

import "fmt"

func main() {
	lines := []string{"12", "", "7"}

	for i := 0; i < len(lines); i++ {
		if lines[i] == "" {
			continue
		}
		fmt.Println("three clauses:", lines[i])
	}

	i := 0
	for i < len(lines) {
		if lines[i] == "" {
			continue
		}
		fmt.Println("condition only:", lines[i])
		i++
	}
}
EOF
quiet flow-skip 'go mod init example.com/skip'

block skip
on flow-skip 'go build'
on flow-skip 'timeout 2 ./skip; echo $?'
on flow-skip 'go vet; echo $?'

lab fresh flow-outside
put flow-outside/main.go <<'EOF'
package main

import "fmt"

func check(n int) {
	if n < 0 {
		break
	}
	if n == 0 {
		continue
	}
	fmt.Println(n)
}

func main() {
	for _, n := range []int{3, 0, -1, 5} {
		check(n)
	}
}
EOF
quiet flow-outside 'go mod init example.com/outside'

block outside
on flow-outside 'go build'

# ---------------------------------------------------------------- labels
lab fresh flow-grid
put flow-grid/main.go <<'EOF'
// Command grid finds the first value above 20, reading row by row.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, 25, 36},
		{49, 64, 81},
	}
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break
			}
		}
	}
}
EOF
quiet flow-grid 'go mod init example.com/grid'

block grid-bug
on flow-grid 'go run .'

put flow-grid/main.go <<'EOF'
// Command grid finds the first value above 20, reading row by row.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, 25, 36},
		{49, 64, 81},
	}
search:
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break
			}
		}
	}
}
EOF

block grid-unused
on flow-grid 'go run .'

put flow-grid/main.go <<'EOF'
// Command grid finds the first value above 20, reading row by row.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, 25, 36},
		{49, 64, 81},
	}
search:
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break search
			}
		}
	}
}
EOF

block grid-fixed
on flow-grid 'go run .'

lab fresh flow-rows
put flow-rows/main.go <<'EOF'
// Command rows adds up each row of a grid that has no negative value in it.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, -25, 36},
		{49, 64, 81},
	}
rows:
	for r, row := range grid {
		sum := 0
		for _, v := range row {
			if v < 0 {
				fmt.Println("row", r, "skipped: it has", v)
				continue rows
			}
			sum += v
		}
		fmt.Println("row", r, "sum", sum)
	}
}
EOF
quiet flow-rows 'go mod init example.com/rows'

block rows
on flow-rows 'go run .'

lab fresh flow-wrong
put flow-wrong/main.go <<'EOF'
package main

import "fmt"

func main() {
	for r := 0; r < 3; r++ {
	inner:
		for c := 0; c < 3; c++ {
			fmt.Println(r, c)
		}
		if r == 1 {
			break inner
		}
	}
}
EOF
quiet flow-wrong 'go mod init example.com/wrong'

block wrong-label
on flow-wrong 'go build'

lab fresh flow-switch
put flow-switch/main.go <<'EOF'
// Command commands runs a list of commands and should stop at "stop".
package main

import "fmt"

func main() {
	commands := []string{"add", "list", "stop", "delete"}
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break
		default:
			fmt.Println("running", c)
		}
	}
	fmt.Println("done")
}
EOF
quiet flow-switch 'go mod init example.com/commands'

block switch-bug
on flow-switch 'go run .'
on flow-switch 'go vet; echo $?'

put flow-switch/main.go <<'EOF'
// Command commands runs a list of commands and should stop at "stop".
package main

import "fmt"

func main() {
	commands := []string{"add", "list", "stop", "delete"}
loop:
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break loop
		default:
			fmt.Println("running", c)
		}
	}
	fmt.Println("done")
}
EOF

block switch-fixed
on flow-switch 'go run .'

# ---------------------------------------------------------------- goto
lab fresh flow-goto
put flow-goto/main.go <<'EOF'
package main

import "fmt"

func main() {
	i := 0
again:
	fmt.Println("turn", i)
	i++
	if i < 3 {
		goto again
	}
	fmt.Println("after", i, "turns")
}
EOF
quiet flow-goto 'go mod init example.com/turns'

block goto-loop
on flow-goto 'go run .'

lab fresh flow-jump
put flow-jump/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := len("hello")
	if n > 3 {
		goto done
	}
	msg := "short"
	fmt.Println(msg)
done:
	fmt.Println("finished")

	goto inside
	if n > 0 {
	inside:
		fmt.Println("inside the if")
	}
}
EOF
quiet flow-jump 'go mod init example.com/jump'

block goto-errors
on flow-jump 'go build'

block stdlib
on flow-goto "grep -c 'goto childerror' /usr/local/go/src/syscall/exec_linux.go"
on flow-goto "sed -n '228,232p' /usr/local/go/src/syscall/exec_linux.go"
on flow-goto "sed -n '678,683p' /usr/local/go/src/syscall/exec_linux.go"
on flow-goto "grep -rE --include=*.go '^\\s*goto\\b' /usr/local/go/src | grep -vc -e _test.go -e testdata"
on flow-goto "grep -rE --include=*.go '^\\s*break\\b' /usr/local/go/src | grep -vc -e _test.go -e testdata"
