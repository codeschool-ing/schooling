#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of go, as a script that produces them.
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
# lesson 4 showed and this lesson does not repeat. Nothing in this lesson
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
module() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

# --- section no-implicit -------------------------------------------------------

module convert
put convert/main.go <<'EOF'
package main

import "fmt"

func main() {
	var count int = 3
	var total int64 = 10
	var price float64 = 2.5

	fmt.Println(total + count)
	fmt.Println(price * count)
}
EOF

block mismatched
on convert 'go run .; echo $?'

module convert-fixed
put convert-fixed/main.go <<'EOF'
package main

import "fmt"

func main() {
	var count int = 3
	var total int64 = 10
	var price float64 = 2.5

	fmt.Println(total + int64(count))
	fmt.Println(price * float64(count))
}
EOF

block fixed
on convert-fixed 'go run .'

module convert-const
put convert-const/main.go <<'EOF'
package main

import "fmt"

func main() {
	var price float64 = 2.5
	count := 3
	const n = 3
	const m int = 3

	fmt.Println(price * 3)
	fmt.Println(price * n)
	fmt.Println(price * m)
	fmt.Println(count * 2.5)
}
EOF

block untyped
on convert-const 'go run .'

# --- section conversions -------------------------------------------------------

module convert-how
put convert-how/main.go <<'EOF'
package main

import "fmt"

func main() {
	f := 3.9
	fmt.Println(int(f), int(-f))

	big, mid := 300, 200
	fmt.Println(int8(big), int8(mid), uint8(mid))

	total, count := 10, 4
	fmt.Println(total / count)
	fmt.Println(float64(total / count))
	fmt.Println(float64(total) / float64(count))
}
EOF

block how
on convert-how 'go run .'

module convert-constconv
put convert-constconv/main.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println(int(3.9))
	fmt.Println(int8(300))
}
EOF

block constconv
on convert-constconv 'go run .'

module convert-rune
put convert-rune/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n := 65
	fmt.Println(string(n))
	fmt.Println(string(rune(n)), strconv.Itoa(n))
}
EOF

block rune
on convert-rune 'go run .'
on convert-rune 'go vet; echo $?'

module convert-atoi
put convert-atoi/main.go <<'EOF'
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n, err := strconv.Atoi("42")
	fmt.Println(n+1, err)

	n, err = strconv.Atoi("4.5")
	fmt.Println(n, err)

	n, err = strconv.Atoi(" 42")
	fmt.Println(n, err)

	n, err = strconv.Atoi("99999999999999999999")
	fmt.Println(n, err)

	s := strconv.Itoa(1500)
	fmt.Println(s+" ms", len(s))
}
EOF

block atoi
on convert-atoi 'go run .'

# --- section named-types -------------------------------------------------------

module convert-temp
put convert-temp/main.go <<'EOF'
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func main() {
	var boil Celsius = 100
	var body Fahrenheit = 98.6
	var reading float64 = 21.5

	fmt.Println(boil + body)
	var room Celsius = reading
	fmt.Println(room)
}
EOF

block temp-refused
on convert-temp 'go run .'

module convert-temp2
put convert-temp2/main.go <<'EOF'
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func CToF(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

func main() {
	var boil Celsius = 100
	fmt.Println(Fahrenheit(boil))
	fmt.Println(CToF(boil))

	var reading float64 = 21.5
	room := Celsius(reading)
	fmt.Printf("%v %T\n", room, room)
}
EOF

block temp-converted
on convert-temp2 'go run .'

module convert-dur
put convert-dur/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(n * time.Second)
}
EOF

block duration-refused
on convert-dur 'go run .'
on convert-dur 'go doc time.Duration | head -6'

module convert-dur2
put convert-dur2/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(time.Duration(n) * time.Second)
	fmt.Println(time.Duration(n))
}
EOF

block duration
on convert-dur2 'go run .'

module convert-alias
put convert-alias/main.go <<'EOF'
package main

import "fmt"

type Celsius float64
type Reading = float64

func main() {
	var x float64 = 21.5
	var r Reading = x
	c := Celsius(x)
	fmt.Printf("%T %T\n", r, c)
	fmt.Println(r + x)
}
EOF

block alias
on convert-alias 'go run .'
on convert-alias 'go doc builtin.byte'
