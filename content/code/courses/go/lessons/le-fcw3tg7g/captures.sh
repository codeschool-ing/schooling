#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of go, as a script that produces them.
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
# between runs.
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

# --- parameters -------------------------------------------------------------
mod funcs
put funcs/main.go <<'EOF'
package main

import "fmt"

func area(width int, height int) int {
	return width * height
}

func perimeter(width, height int) int {
	return 2 * (width + height)
}

func label(name string, width, height int, unit string) string {
	return fmt.Sprintf("%s: %d%s", name, area(width, height), unit)
}

func ruler() {
	fmt.Println("----------")
}

func main() {
	fmt.Println(area(3, 4), perimeter(3, 4))
	ruler()
	fmt.Println(label("kitchen", 3, 4, " m2"))
}
EOF

block params
on funcs 'go run .'

mod funcs-c
put funcs-c/main.go <<'EOF'
package main

import "fmt"

func area(int width, int height) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4))
}
EOF

block c-style
on funcs-c 'go run .'

mod funcs-default
put funcs-default/main.go <<'EOF'
package main

import "fmt"

func greet(name string, greeting string = "Hello") {
	fmt.Println(greeting+",", name)
}

func main() {
	greet("Ana")
}
EOF

block default
on funcs-default 'go run .'

mod funcs-overload
put funcs-overload/main.go <<'EOF'
package main

import "fmt"

func area(side int) int {
	return side * side
}

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3), area(3, 4))
}
EOF

block overload
on funcs-overload 'go run .'
on funcs-overload "go doc strings | grep -E '^func (Index|IndexByte|IndexRune|Split|SplitN)\('"

mod funcs-args
put funcs-args/main.go <<'EOF'
package main

import "fmt"

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3))
	fmt.Println(area(3, 4, 5))
	fmt.Println(area(3, "4"))
}
EOF

block args
on funcs-args 'go run .'

mod funcs-unusedparam
put funcs-unusedparam/main.go <<'EOF'
package main

import "fmt"

func area(width, height int, unit string) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4, "m2"))
}
EOF

block unused-param
on funcs-unusedparam 'go vet && go run .'

# --- multiple-returns -------------------------------------------------------
mod funcs-multi
put funcs-multi/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
	"unicode/utf8"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q, r := divmod(17, 5)
	fmt.Println(q, r)
	fmt.Println(divmod(17, 5))

	n, err := strconv.Atoi("42")
	fmt.Println(n, err)
	n, err = strconv.Atoi("42x")
	fmt.Println(n, err)

	ch, size := utf8.DecodeRuneInString("épée")
	fmt.Printf("%c %d\n", ch, size)
}
EOF

block multi
on funcs-multi 'go run .'

mod funcs-mismatch
put funcs-mismatch/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q := divmod(17, 5)
	fmt.Println("17 / 5 is", divmod(17, 5))
	n := strconv.Atoi("42")
	fmt.Println(q, n)
}
EOF

block mismatch
on funcs-mismatch 'go run .'

mod funcs-blank
put funcs-blank/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	_, r := divmod(17, 5)
	fmt.Println(r)

	n, _ := strconv.Atoi("42x")
	fmt.Println(n + 1)
}
EOF

block blank
on funcs-blank 'go run .'

mod funcs-unread
put funcs-unread/main.go <<'EOF'
package main

import "fmt"

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q, r := divmod(17, 5)
	fmt.Println(q)
}
EOF

block unread
on funcs-unread 'go run .'

mod funcs-missing
put funcs-missing/main.go <<'EOF'
package main

import "fmt"

func sign(n int) string {
	if n < 0 {
		return "negative"
	}
	if n > 0 {
		return "positive"
	}
}

func main() {
	fmt.Println(sign(-3))
}
EOF

block missing
on funcs-missing 'go run .'

# --- named-returns ----------------------------------------------------------
block doc-cut
on funcs-multi 'go doc strings.Cut'

mod funcs-named
put funcs-named/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

func nothing() (n int, s string, err error) {
	return
}

func setting(line string) (key, value string, ok bool) {
	key, value, ok = strings.Cut(line, "=")
	key = strings.TrimSpace(key)
	value = strings.TrimSpace(value)
	return
}

func main() {
	n, s, err := nothing()
	fmt.Printf("%d %q %v\n", n, s, err)
	fmt.Println(setting("port = 8080"))
	fmt.Println(setting("verbose"))
}
EOF

block named
on funcs-named 'go run .'

mod funcs-shadow
put funcs-shadow/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
EOF

block shadow
on funcs-shadow 'go run .'

mod funcs-shadow2
put funcs-shadow2/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return n, err
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
EOF

block shadow2
on funcs-shadow2 'go vet && go run .'

mod funcs-defer
put funcs-defer/main.go <<'EOF'
package main

import "fmt"

func answer() (n int) {
	defer func() {
		n++
	}()
	return 41
}

func main() {
	fmt.Println(answer())
}
EOF

block defer
on funcs-defer 'go run .'
