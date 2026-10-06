#!/usr/bin/env bash
# The terminal sessions quoted in lesson 35 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. sentinel-v2 and
# sentinel-v3 are copies of sentinel-store with store/store.go changed the
# way the lesson says, and main.go untouched.
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

# ---- section 02: io.EOF ends a loop, and is not a failure
lab fresh sentinel
put sentinel/main.go <<'EOF'
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	r := strings.NewReader("Hello, Go")
	buf := make([]byte, 4)
	for {
		n, err := r.Read(buf)
		fmt.Printf("%d %q %v\n", n, buf[:n], err)
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Println("read failed:", err)
			return
		}
	}
	fmt.Println("done")
}
EOF
quiet sentinel 'go mod init example.com/sentinel'

block eof
on sentinel 'go run .'

block eofdoc
on sentinel 'go doc io.EOF'
on sentinel 'go doc io.ReadAll'

block iovars
on sentinel "go doc io | grep '^var'"

# ---- section 03: a sentinel of your own, in a package of its own
lab fresh sentinel-store
put sentinel-store/store/store.go <<'EOF'
// Package store keeps the shop's stock in memory.
package store

import (
	"errors"
	"fmt"
)

// ErrNotFound means the store does not sell the item asked for.
var ErrNotFound = errors.New("not found")

var stock = map[string]int{"apple": 12, "pear": 0}

// Count reports how many of an item are in stock. For an item the store
// does not sell, the error wraps ErrNotFound.
func Count(item string) (int, error) {
	n, ok := stock[item]
	if !ok {
		return 0, fmt.Errorf("count %q: %w", item, ErrNotFound)
	}
	return n, nil
}
EOF
put sentinel-store/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"

	"example.com/shop/store"
)

func main() {
	for _, item := range []string{"apple", "pear", "plum"} {
		n, err := store.Count(item)
		switch {
		case errors.Is(err, store.ErrNotFound):
			fmt.Printf("%s: not sold here (%v)\n", item, err)
		case err != nil:
			fmt.Printf("%s: failed: %v\n", item, err)
		default:
			fmt.Printf("%s: %d in stock\n", item, n)
		}
	}
}
EOF
quiet sentinel-store 'go mod init example.com/shop'

block store
on sentinel-store 'go run .'
on sentinel-store 'go doc ./store'
on sentinel-store 'go doc ./store Count'

# ---- section 04: the sentinel stops being returned (v2) or is deleted (v3)
lab fresh sentinel-v2
quiet sentinel-v2 'cp -r ~/sentinel-store/. .'
put sentinel-v2/store/store.go <<'EOF'
// Package store keeps the shop's stock in memory.
package store

import (
	"errors"
	"fmt"
)

// ErrNotFound means the store does not sell the item asked for.
var ErrNotFound = errors.New("not found")

var stock = map[string]int{"apple": 12, "pear": 0}

// Count reports how many of an item are in stock. For an item the store
// does not sell, the error wraps ErrNotFound.
func Count(item string) (int, error) {
	n, ok := stock[item]
	if !ok {
		return 0, fmt.Errorf("count %q: not found", item)
	}
	return n, nil
}
EOF

block v2
on sentinel-v2 'go vet && go run .'

lab fresh sentinel-v3
quiet sentinel-v3 'cp -r ~/sentinel-store/. .'
put sentinel-v3/store/store.go <<'EOF'
// Package store keeps the shop's stock in memory.
package store

import "fmt"

var stock = map[string]int{"apple": 12, "pear": 0}

// Count reports how many of an item are in stock.
func Count(item string) (int, error) {
	n, ok := stock[item]
	if !ok {
		return 0, fmt.Errorf("count %q: not found", item)
	}
	return n, nil
}
EOF

block v3
on sentinel-v3 'go run .; echo $?'

# ---- section 04: a type that carries a sentinel
lab fresh sentinel-strconv
put sentinel-strconv/main.go <<'EOF'
package main

import (
	"errors"
	"fmt"
	"strconv"
)

func main() {
	for _, s := range []string{"42", "4x2", "99999999999999999999"} {
		n, err := strconv.Atoi(s)
		switch {
		case err == nil:
			fmt.Println(s, "->", n)
		case errors.Is(err, strconv.ErrSyntax):
			fmt.Println(s, "-> not a number")
		case errors.Is(err, strconv.ErrRange):
			fmt.Println(s, "-> too big for an int")
		}
		if ne, ok := errors.AsType[*strconv.NumError](err); ok {
			fmt.Printf("   Func=%s Num=%q Err=%v\n", ne.Func, ne.Num, ne.Err)
		}
	}
}
EOF
quiet sentinel-strconv 'go mod init example.com/numbers'

block strconv
on sentinel-strconv 'go run .'
on sentinel-strconv 'go doc strconv.NumError'
