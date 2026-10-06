#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of go, as a script that produces them.
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
# lesson 4 already showed. The timings and the memory addresses differ between
# machines and builds; the lesson quotes one run of this script.
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

# --- literals -------------------------------------------------------------

lab fresh strings-lit
put strings-lit/main.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println("tab:\tend")
	fmt.Println("quote: \" backslash: \\")
	fmt.Println("euro: \u20ac, A: \x41, \101")
	fmt.Println(`tab:\tend`)
	fmt.Println(len("\n"), len(`\n`))
}
EOF
quiet strings-lit 'go mod init example.com/lit'

block lit
on strings-lit 'go run .'

lab fresh strings-newline
put strings-newline/main.go <<'EOF'
package main

import "fmt"

func main() {
	usage := "usage: greet [-n name]
  -n name   who to greet"
	fmt.Println(usage)
}
EOF
quiet strings-newline 'go mod init example.com/newline'

block newline
on strings-newline 'go run .'

lab fresh strings-escape
put strings-escape/main.go <<'EOF'
package main

import "fmt"

func main() {
	pattern := "\d+"
	fmt.Println(pattern)
}
EOF
quiet strings-escape 'go mod init example.com/escape'

block escape
on strings-escape 'go run .'

lab fresh strings-path
put strings-path/main.go <<'EOF'
package main

import "fmt"

func main() {
	path := "C:\new\table"
	fmt.Println(path)
	fmt.Printf("%q\n", path)
	fmt.Println(`C:\new\table`)
}
EOF
quiet strings-path 'go mod init example.com/path'

block path
on strings-path 'go vet; echo $?'
on strings-path 'go run .'

lab fresh strings-raw
put strings-raw/main.go <<'EOF'
package main

import "fmt"

func main() {
	usage := `usage: greet [-n name]

  -n name   who to greet, default "world"`
	pattern := `\d+\.\d+`
	fmt.Println(usage)
	fmt.Println(pattern, len(pattern))
}
EOF
quiet strings-raw 'go mod init example.com/raw'

block raw
on strings-raw 'go run .'

# --- immutable ------------------------------------------------------------

lab fresh strings-mut
put strings-mut/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := "hello"
	s[0] = 'H'
	fmt.Println(s)
}
EOF
quiet strings-mut 'go mod init example.com/mut'

block mut
on strings-mut 'go run .'

lab fresh strings-share
put strings-share/main.go <<'EOF'
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	s := "hello, world"
	t := s
	s = "H" + s[1:]
	fmt.Println(s)
	fmt.Println(t)

	fmt.Println(unsafe.Sizeof(t), unsafe.Sizeof("a"), len(t))

	w := t[7:]
	fmt.Println(unsafe.StringData(t), unsafe.StringData(w), w)

	u := t[:5] + "!"
	fmt.Println(unsafe.StringData(u) == unsafe.StringData(t), u)
}
EOF
quiet strings-share 'go mod init example.com/share'

block share
on strings-share 'go run .'

lab fresh strings-plus
put strings-plus/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := ""
	for range 100000 {
		s += "ab"
	}
	fmt.Println(len(s))
}
EOF
quiet strings-plus 'go mod init example.com/plus'

lab fresh strings-builder
put strings-builder/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

func main() {
	var b strings.Builder
	for range 100000 {
		b.WriteString("ab")
	}
	s := b.String()
	fmt.Println(len(s))
}
EOF
quiet strings-builder 'go mod init example.com/builder'

block plus
on strings-plus 'go build && time ./plus'
block builder
on strings-builder 'go build && time ./builder'

# --- utf8 -----------------------------------------------------------------

lab fresh strings-bytes
put strings-bytes/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
	"unicode/utf8"
)

func main() {
	s := "café"
	fmt.Println(len(s), utf8.RuneCountInString(s))
	fmt.Println(utf8.RuneCountInString("cafe\u0301"))
	fmt.Println(s[0], s[3], s[4])
	fmt.Printf("%T %c\n", s[3], s[3])
	fmt.Printf("%q %q\n", s[:3], s[:4])
	fmt.Println(utf8.ValidString(s[:4]), utf8.ValidString(s))
	fmt.Println(strings.Index("café au lait", "au"))
	r, size := utf8.DecodeRuneInString(s[3:])
	fmt.Printf("%c %d\n", r, size)
}
EOF
quiet strings-bytes 'go mod init example.com/bytes'

block bytes
on strings-bytes 'go run .'

lab fresh strings-invalid
put strings-invalid/main.go <<'EOF'
package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	b := "\xff\xfe"
	fmt.Println(len(b), utf8.ValidString(b), utf8.RuneCountInString(b))
	fmt.Printf("%q % x\n", b, b)
}
EOF
quiet strings-invalid 'go mod init example.com/invalid'

block invalid
on strings-invalid 'go run .'
