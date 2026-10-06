#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of go, as a script that produces them.
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

# ---------------------------------------------------------------- if-else
lab fresh cond
put cond/main.go <<'EOF'
// Command sign says whether each number is negative, zero or positive.
package main

import "fmt"

func main() {
	for _, n := range []int{-4, 0, 7} {
		if n < 0 {
			fmt.Println(n, "is negative")
		} else if n == 0 {
			fmt.Println(n, "is zero")
		} else {
			fmt.Println(n, "is positive")
		}
	}
}
EOF
quiet cond 'go mod init example.com/sign'

block sign
on cond 'go run .'

lab fresh cond-parens
put cond-parens/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 7
	if (n > 0) {
		fmt.Println(n, "is positive")
	}
}
EOF
quiet cond-parens 'go mod init example.com/parens'

block parens
on cond-parens 'go run .'
on cond-parens 'gofmt -d main.go'

lab fresh cond-braces
put cond-braces/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 7
	if n > 0 fmt.Println(n, "is positive")
}
EOF
quiet cond-braces 'go mod init example.com/braces'

block braces
on cond-braces 'go build'

lab fresh cond-else
put cond-else/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 7
	if n > 0 {
		fmt.Println(n, "is positive")
	}
	else {
		fmt.Println(n, "is not positive")
	}
}
EOF
quiet cond-else 'go mod init example.com/else'

block else
on cond-else 'go build'
on cond-else 'go doc go/scanner.Scanner.Scan | sed -n 13,15p'

lab fresh cond-brace
put cond-brace/main.go <<'EOF'
package main

import "fmt"

func main()
{
	fmt.Println("hello")
}
EOF
quiet cond-brace 'go mod init example.com/brace'

block brace-line
on cond-brace 'go build'

# ---------------------------------------------------------------- initialiser
lab fresh cond-init
put cond-init/main.go <<'EOF'
// Command size says how large each number in a list is.
package main

import (
	"fmt"
	"strconv"
)

func main() {
	for _, s := range []string{"42", "7", "forty-two"} {
		if n, err := strconv.Atoi(s); err != nil {
			fmt.Println("not a number:", err)
		} else if n > 10 {
			fmt.Println(n, "is more than ten")
		} else {
			fmt.Println(n, "is ten or less")
		}
	}
}
EOF
quiet cond-init 'go mod init example.com/size'

block init
on cond-init 'go run .'

put cond-init/main.go <<'EOF'
// Command size says how large each number in a list is.
package main

import (
	"fmt"
	"strconv"
)

func main() {
	for _, s := range []string{"42", "7", "forty-two"} {
		if n, err := strconv.Atoi(s); err != nil {
			fmt.Println("not a number:", err)
		} else if n > 10 {
			fmt.Println(n, "is more than ten")
		} else {
			fmt.Println(n, "is ten or less")
		}
		fmt.Println("done with", n)
	}
}
EOF

block init-scope
on cond-init 'go build'

lab fresh cond-after
put cond-after/main.go <<'EOF'
// Command double doubles numbers written as text.
package main

import (
	"fmt"
	"strconv"
)

func double(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return n * 2, nil
}

func main() {
	fmt.Println(double("21"))
	fmt.Println(double("twenty-one"))
}
EOF
quiet cond-after 'go mod init example.com/double'

block after
on cond-after 'go run .'

lab fresh cond-early
put cond-early/main.go <<'EOF'
// Command price works out a ticket's price twice, in two shapes.
package main

import "fmt"

func priceNested(age int, member bool) int {
	if age >= 0 {
		if age < 12 {
			return 0
		} else {
			if member {
				return 15
			} else {
				return 20
			}
		}
	} else {
		return -1
	}
}

func priceFlat(age int, member bool) int {
	if age < 0 {
		return -1
	}
	if age < 12 {
		return 0
	}
	if member {
		return 15
	}
	return 20
}

func main() {
	fmt.Println(priceNested(8, false), priceNested(30, true), priceNested(30, false), priceNested(-1, false))
	fmt.Println(priceFlat(8, false), priceFlat(30, true), priceFlat(30, false), priceFlat(-1, false))
}
EOF
quiet cond-early 'go mod init example.com/price'

block early
on cond-early 'go run .'

# ---------------------------------------------------------------- switch
lab fresh cond-switch
put cond-switch/main.go <<'EOF'
// Command days says what kind of day each one is.
package main

import "fmt"

func main() {
	for _, d := range []string{"mon", "sat", "fri", "sun", "xyz"} {
		switch d {
		case "sat", "sun":
			fmt.Println(d, "weekend")
		case "fri":
			fmt.Println(d, "almost the weekend")
		case "mon", "tue", "wed", "thu":
			fmt.Println(d, "weekday")
		default:
			fmt.Println(d, "not a day")
		}
	}
}
EOF
quiet cond-switch 'go mod init example.com/days'

block days
on cond-switch 'go run .'

lab fresh cond-dup
put cond-dup/main.go <<'EOF'
package main

import "fmt"

func main() {
	d := "sat"
	switch d {
	case "sat", "sun":
		fmt.Println(d, "weekend")
	case "fri", "sat":
		fmt.Println(d, "going out")
	}
}
EOF
quiet cond-dup 'go mod init example.com/dup'

block dup
on cond-dup 'go build'

lab fresh cond-ext
put cond-ext/main.go <<'EOF'
// Command kind names the kind of each file from its extension.
package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

func main() {
	for _, name := range []string{"main.go", "README.md", "logo.PNG", "Makefile"} {
		switch ext := strings.ToLower(filepath.Ext(name)); ext {
		case ".go":
			fmt.Println(name, "Go source")
		case ".png", ".jpg":
			fmt.Println(name, "image")
		case "":
			fmt.Println(name, "no extension")
		default:
			fmt.Println(name, "something else:", ext)
		}
	}
}
EOF
quiet cond-ext 'go mod init example.com/kind'

block ext
on cond-ext 'go run .'

lab fresh cond-grade
put cond-grade/main.go <<'EOF'
// Command grade turns scores into grades.
package main

import "fmt"

func grade(score int) string {
	switch {
	case score >= 50:
		return "pass"
	case score >= 90:
		return "distinction"
	default:
		return "fail"
	}
}

func main() {
	for _, s := range []int{95, 70, 30} {
		fmt.Println(s, grade(s))
	}
}
EOF
quiet cond-grade 'go mod init example.com/grade'

block grade-bug
on cond-grade 'go run .'

put cond-grade/main.go <<'EOF'
// Command grade turns scores into grades.
package main

import "fmt"

func grade(score int) string {
	switch {
	case score >= 90:
		return "distinction"
	case score >= 50:
		return "pass"
	default:
		return "fail"
	}
}

func main() {
	for _, s := range []int{95, 70, 30} {
		fmt.Println(s, grade(s))
	}
}
EOF

block grade-fixed
on cond-grade 'go run .'

lab fresh cond-fall
put cond-fall/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
		fallthrough
	case n > 100:
		fmt.Println(n, "is more than 100")
	default:
		fmt.Println(n, "is something else")
	}
}
EOF
quiet cond-fall 'go mod init example.com/fall'

block fall
on cond-fall 'go run .'

put cond-fall/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
	default:
		fmt.Println(n, "is something else")
		fallthrough
	}
}
EOF

block fall-final
on cond-fall 'go build'

block stdlib
on cond-fall "grep -rE --include=*.go '^\\s*switch\\b' /usr/local/go/src | grep -vc -e _test.go -e testdata"
on cond-fall "grep -rE --include=*.go '^\\s*fallthrough\\b' /usr/local/go/src | grep -vc -e _test.go -e testdata"
