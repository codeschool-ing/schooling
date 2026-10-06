#!/usr/bin/env bash
# The terminal sessions quoted in lesson 32 of go, as a script that produces them.
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
# lesson 4 showed and this one does not repeat. ~/errors-nil and
# ~/errors-nilfix differ in one line, the result type of `check`. The
# count of lines in /usr/local/go/src reads the Go 1.27.1 source the lab
# installed. `notes.txt` does not exist in ~/errors on purpose. Nothing in the
# output varies between runs.
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

# ---------------------------------------------------------------- the-interface
lab fresh errors
put errors/main.go <<'EOF'
// Command errors looks at two errors from the standard library.
package main

import (
	"fmt"
	"os"
	"strconv"
)

func main() {
	f, err := os.Open("notes.txt")
	fmt.Println(f, err)
	fmt.Printf("%T\n", err)

	n, err := strconv.Atoi("12")
	fmt.Println(n, err, err == nil)

	n, err = strconv.Atoi("12a")
	fmt.Println(n, err, err == nil)
	fmt.Printf("%T\n", err)
	fmt.Println(err.Error())
}
EOF
quiet errors 'go mod init example.com/errors'

block doc-error
on errors 'go doc builtin.error'

block run-errors
on errors 'go run .'

block doc-open
on errors 'go doc os.Open'
on errors 'go doc os.PathError'

lab fresh errors-truthy
put errors-truthy/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func main() {
	_, err := strconv.Atoi("12a")
	if err {
		fmt.Println(err)
	}
}
EOF
quiet errors-truthy 'go mod init example.com/truthy'

block truthy
on errors-truthy 'go run .'

# ---------------------------------------------------------------- the-idiom
lab fresh errors-idiom
put errors-idiom/main.go <<'EOF'
// Command price prints the price of a ticket for the age it is given.
package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
)

func price(age int, member bool) (int, error) {
	if age < 0 {
		return 0, errors.New("age cannot be negative")
	}
	if age < 12 {
		return 0, nil
	}
	if member {
		return 15, nil
	}
	return 20, nil
}

func main() {
	age, err := strconv.Atoi(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	p, err := price(age, false)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(p)
}
EOF
quiet errors-idiom 'go mod init example.com/price'

block idiom
on errors-idiom 'go build -o price .'
on errors-idiom './price 30; echo $?'
on errors-idiom './price 8; echo $?'
on errors-idiom './price -4; echo $?'
on errors-idiom './price thirty; echo $?'
on errors-idiom './price -4 2>/dev/null; echo $?'

lab fresh errors-ignore
put errors-ignore/main.go <<'EOF'
// Command price prints the price of a ticket for the age it is given.
package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
)

func price(age int, member bool) (int, error) {
	if age < 0 {
		return 0, errors.New("age cannot be negative")
	}
	if age < 12 {
		return 0, nil
	}
	if member {
		return 15, nil
	}
	return 20, nil
}

func main() {
	age, _ := strconv.Atoi(os.Args[1])
	p, _ := price(age, false)
	fmt.Println(p)
}
EOF
quiet errors-ignore 'go mod init example.com/price'

block ignore
on errors-ignore 'go run . thirty'
on errors-ignore 'go run . -4'

block count
on errors-idiom "grep -rE --include=*.go 'if err != nil' /usr/local/go/src | grep -vc -e _test.go -e testdata"

# ---------------------------------------------------------------- custom-errors
lab fresh errors-custom
put errors-custom/main.go <<'EOF'
// Command config checks the lines of a small configuration text.
package main

import (
	"fmt"
	"strings"
)

// A LineError says which line of the input was wrong, and why.
type LineError struct {
	Line int
	Msg  string
}

func (e *LineError) Error() string {
	return fmt.Sprintf("line %d: %s", e.Line, e.Msg)
}

func check(text string) error {
	for i, line := range strings.Split(text, "\n") {
		if line != "" && !strings.Contains(line, "=") {
			return &LineError{Line: i + 1, Msg: "no = in " + line}
		}
	}
	return nil
}

func main() {
	fmt.Println(check("port=8080\nhost=localhost"))
	err := check("port=8080\nhost localhost")
	fmt.Println(err)
	fmt.Printf("%T\n", err)
}
EOF
quiet errors-custom 'go mod init example.com/config'

block custom
on errors-custom 'go run .'

lab fresh errors-nil
put errors-nil/main.go <<'EOF'
// Command config checks the lines of a small configuration text.
package main

import (
	"fmt"
	"strings"
)

// A LineError says which line of the input was wrong, and why.
type LineError struct {
	Line int
	Msg  string
}

func (e *LineError) Error() string {
	return fmt.Sprintf("line %d: %s", e.Line, e.Msg)
}

func check(text string) *LineError {
	for i, line := range strings.Split(text, "\n") {
		if line != "" && !strings.Contains(line, "=") {
			return &LineError{Line: i + 1, Msg: "no = in " + line}
		}
	}
	return nil
}

func load(text string) error {
	return check(text)
}

func main() {
	err := load("port=8080\nhost=localhost")
	fmt.Printf("%T %v\n", err, err == nil)
	if err != nil {
		fmt.Println("load failed:", err)
		fmt.Println(err.Error())
	}
}
EOF
quiet errors-nil 'go mod init example.com/config'

block typed-nil
on errors-nil 'go vet && go run .'

block typed-nil-fix
lab fresh errors-nilfix
put errors-nilfix/main.go <<'EOF'
// Command config checks the lines of a small configuration text.
package main

import (
	"fmt"
	"strings"
)

// A LineError says which line of the input was wrong, and why.
type LineError struct {
	Line int
	Msg  string
}

func (e *LineError) Error() string {
	return fmt.Sprintf("line %d: %s", e.Line, e.Msg)
}

func check(text string) error {
	for i, line := range strings.Split(text, "\n") {
		if line != "" && !strings.Contains(line, "=") {
			return &LineError{Line: i + 1, Msg: "no = in " + line}
		}
	}
	return nil
}

func load(text string) error {
	return check(text)
}

func main() {
	err := load("port=8080\nhost=localhost")
	fmt.Printf("%T %v\n", err, err == nil)
	if err != nil {
		fmt.Println("load failed:", err)
		fmt.Println(err.Error())
	}
}
EOF
quiet errors-nilfix 'go mod init example.com/config'
on errors-nilfix 'go vet && go run .'
