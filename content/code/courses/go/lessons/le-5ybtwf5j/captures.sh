#!/usr/bin/env bash
# The terminal sessions quoted in lesson 33 of go, as a script that produces them.
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
# lesson 4 showed and this one does not repeat. `settings.json` does not exist
# in any of these directories on purpose: reading it is the failure every
# program wraps. ~/wrap-context and ~/wrap-style differ only in the words of
# their two calls to fmt.Errorf. The source lines and the counts read the Go
# 1.27.1 tree the lab installed in /usr/local/go/src. Nothing in the output
# varies between runs.
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

# ---------------------------------------------------------------- errors-new
lab fresh wrap
put wrap/main.go <<'EOF'
// Command wrap compares two errors made from the same text.
package main

import (
	"errors"
	"fmt"
)

func main() {
	a := errors.New("not found")
	b := errors.New("not found")
	fmt.Println(a)
	fmt.Println(a == b, a.Error() == b.Error())

	c := a
	fmt.Println(a == c)
	fmt.Printf("%T\n", a)
}
EOF
quiet wrap 'go mod init example.com/wrap'

block new
on wrap 'go run .'

block new-doc
on wrap 'go doc errors.New'
on wrap "sed -n '64,75p' /usr/local/go/src/errors/errors.go"

# ---------------------------------------------------------------- errorf
lab fresh wrap-verbs
put wrap-verbs/main.go <<'EOF'
// Command verbs adds the same words to an error with %v and with %w.
package main

import (
	"fmt"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	v := fmt.Errorf("read config: %v", err)
	w := fmt.Errorf("read config: %w", err)
	fmt.Println(v)
	fmt.Println(w)
	fmt.Printf("%T\n%T\n", v, w)
}
EOF
quiet wrap-verbs 'go mod init example.com/verbs'

block verbs
on wrap-verbs 'go run .'

block verbs-src
on wrap-verbs "sed -n '44,50p;70,73p' /usr/local/go/src/fmt/errors.go"

lab fresh wrap-context
put wrap-context/main.go <<'EOF'
// Command server fails to start, and says why.
package main

import (
	"fmt"
	"os"
)

func readConfig(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}
	return data, nil
}

func start() error {
	if _, err := readConfig("settings.json"); err != nil {
		return fmt.Errorf("start server: %w", err)
	}
	return nil
}

func main() {
	if err := start(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
EOF
quiet wrap-context 'go mod init example.com/server'

block context
on wrap-context 'go run .'

lab fresh wrap-style
put wrap-style/main.go <<'EOF'
// Command server fails to start, and says why.
package main

import (
	"fmt"
	"os"
)

func readConfig(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("Error: could not read config: %w.", err)
	}
	return data, nil
}

func start() error {
	if _, err := readConfig("settings.json"); err != nil {
		return fmt.Errorf("Failed to start server: %w.", err)
	}
	return nil
}

func main() {
	if err := start(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
EOF
quiet wrap-style 'go mod init example.com/server'

block style
on wrap-style 'go run .'

block style-count
on wrap "grep -rE --include=*.go 'errors\.New\(\"' /usr/local/go/src | grep -vc -e _test.go -e testdata"
on wrap "grep -rE --include=*.go 'errors\.New\(\"[A-Z]' /usr/local/go/src | grep -vc -e _test.go -e testdata"
on wrap "grep -rE --include=*.go 'errors\.New\(\"[^\"]*\.\"\)' /usr/local/go/src | grep -vc -e _test.go -e testdata"

lab fresh wrap-vet
put wrap-vet/main.go <<'EOF'
package main

import "fmt"

func main() {
	reason := "disk full"
	err := fmt.Errorf("save notes: %w", reason)
	fmt.Println(err)
}
EOF
quiet wrap-vet 'go mod init example.com/vet'

block vet
on wrap-vet 'go run .'
on wrap-vet 'go vet'

# ---------------------------------------------------------------- several-errors
lab fresh wrap-join
put wrap-join/main.go <<'EOF'
// Command signup checks a form and reports every problem at once.
package main

import (
	"errors"
	"fmt"
)

func validate(name string, age int) error {
	var errs []error
	if name == "" {
		errs = append(errs, errors.New("name is empty"))
	}
	if age < 0 {
		errs = append(errs, fmt.Errorf("age %d is negative", age))
	}
	return errors.Join(errs...)
}

func main() {
	fmt.Println(validate("Ana", 30))
	err := validate("", -4)
	fmt.Println(err)
	fmt.Printf("%T %q\n", err, err.Error())
}
EOF
quiet wrap-join 'go mod init example.com/signup'

block join
on wrap-join 'go run .'
on wrap-join 'go doc errors.Join'

lab fresh wrap-two
put wrap-two/main.go <<'EOF'
// Command save reports two failures of one operation in one message.
package main

import (
	"errors"
	"fmt"
)

func main() {
	writeErr := errors.New("disk full")
	closeErr := errors.New("file already closed")
	err := fmt.Errorf("save notes.txt: %w (and closing it: %w)", writeErr, closeErr)
	fmt.Println(err)
	fmt.Printf("%T\n", err)
}
EOF
quiet wrap-two 'go mod init example.com/save'

block two
on wrap-two 'go run .'
