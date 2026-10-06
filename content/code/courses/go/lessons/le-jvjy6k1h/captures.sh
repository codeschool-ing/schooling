#!/usr/bin/env bash
# The terminal sessions quoted in lesson 34 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. There is no
# settings.json in any of these directories, on purpose: the missing file is
# the error every program here examines. The go1.25.0 toolchain asked for in
# is-as-old is already in ana's module cache, downloaded by lesson 2's
# captures; run on a fresh lab, the go command fetches it from the module
# proxy first.
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

# ---- section 02: the chain, peeled one link at a time
lab fresh is-as
put is-as/main.go <<'EOF'
package main

import (
	"errors"
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
	err := start()
	fmt.Println(err)
	for e := err; e != nil; e = errors.Unwrap(e) {
		fmt.Printf("%-20T %v\n", e, e)
	}
}
EOF
quiet is-as 'go mod init example.com/isas'

block chain
on is-as 'go run .'

# ---- section 02: several %w and errors.Join make a tree, which Unwrap does not walk
lab fresh is-as-tree
put is-as-tree/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
)

func main() {
	both := errors.Join(fs.ErrNotExist, fs.ErrPermission)
	fmt.Printf("%T\n", both)
	fmt.Println(errors.Unwrap(both))
	fmt.Println(errors.Is(both, fs.ErrPermission))
}
EOF
quiet is-as-tree 'go mod init example.com/tree'

block tree
on is-as-tree 'go run .'

# ---- section 03: == against errors.Is
lab fresh is-as-is
put is-as-is/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
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
	err := start()
	fmt.Println("==           ", err == fs.ErrNotExist)
	fmt.Println("errors.Is    ", errors.Is(err, fs.ErrNotExist))
	fmt.Println("os.IsNotExist", os.IsNotExist(err))
	fmt.Println("permission   ", errors.Is(err, fs.ErrPermission))

	if errors.Is(err, fs.ErrNotExist) {
		fmt.Println("no settings.json: starting with the defaults")
	}
}
EOF
quiet is-as-is 'go mod init example.com/isas'

block is
on is-as-is 'go run .'

block isnotexist
on is-as-is 'go doc os.IsNotExist'
on is-as-is 'go doc os.ErrNotExist | grep NotExist'

# ---- section 03: the bottom of the chain is not fs.ErrNotExist
lab fresh is-as-errno
put is-as-errno/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"syscall"
)

func main() {
	_, err := os.ReadFile("settings.json")
	inner := errors.Unwrap(err)
	fmt.Println(inner == fs.ErrNotExist)
	fmt.Println(inner == syscall.ENOENT)
	fmt.Println(syscall.ENOENT.Is(fs.ErrNotExist))
}
EOF
quiet is-as-errno 'go mod init example.com/errno'

block errno
on is-as-errno 'go run .'

# ---- section 03: %v instead of %w, and the chain is cut
lab fresh is-as-cut
put is-as-cut/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func readConfig(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config: %v", err)
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
	err := start()
	fmt.Println(err)
	for e := err; e != nil; e = errors.Unwrap(e) {
		fmt.Printf("%-20T %v\n", e, e)
	}
	fmt.Println(errors.Is(err, fs.ErrNotExist))
}
EOF
quiet is-as-cut 'go mod init example.com/cut'

block cut
on is-as-cut 'go run .'

# ---- section 04: errors.As and errors.AsType
lab fresh is-as-as
put is-as-as/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
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
	err := start()

	_, ok := err.(*fs.PathError)
	fmt.Println("assertion:", ok)

	var pe *fs.PathError
	if errors.As(err, &pe) {
		fmt.Println("Op:  ", pe.Op)
		fmt.Println("Path:", pe.Path)
		fmt.Println("Err: ", pe.Err)
	}

	if pe, ok := errors.AsType[*fs.PathError](err); ok {
		fmt.Println("AsType found", pe.Path)
	}
}
EOF
quiet is-as-as 'go mod init example.com/isas'

block pathdoc
on is-as-as 'go doc fs.PathError'

block as
on is-as-as 'go run .'

# ---- section 04: a target that is not a pointer
lab fresh is-as-panic
put is-as-panic/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	var pe *fs.PathError
	if errors.As(err, pe) {
		fmt.Println(pe.Path)
	}
}
EOF
quiet is-as-panic 'go mod init example.com/panic'

block panic
on is-as-panic 'go vet; echo $?'
on is-as-panic 'go build && ./panic 2>&1 | head -3'
on is-as-panic './panic 2>/dev/null; echo $?'

# ---- section 04: AsType checks its type argument when it compiles
lab fresh is-as-value
put is-as-value/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	if pe, ok := errors.AsType[fs.PathError](err); ok {
		fmt.Println(pe.Path)
	}
}
EOF
quiet is-as-value 'go mod init example.com/value'

block value
on is-as-value 'go run .; echo $?'

# ---- section 04: the same mistake with errors.As compiles, and vet reports it
lab fresh is-as-value2
put is-as-value2/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	var pe fs.PathError
	if errors.As(err, &pe) {
		fmt.Println(pe.Path)
	}
}
EOF
quiet is-as-value2 'go mod init example.com/value'

block value2
on is-as-value2 'go vet; echo $?'
on is-as-value2 'go build && ./value 2>&1 | head -1'

# ---- section 04: AsType is not in an older release
lab fresh is-as-old
block old
on is-as-old 'go doc errors.As | head -10'
on is-as-old 'go doc errors.AsType | head -3'
on is-as-old 'GOTOOLCHAIN=go1.25.0 go doc errors.AsType'
on is-as-old 'GOTOOLCHAIN=go1.26.0 go doc errors.AsType | head -3'
