#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. The 32-bit run uses
# GOARCH=386, which the lab's amd64 machine executes directly.
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

lab fresh numbers
put numbers/main.go <<'EOF'
// Command intsize prints how wide int is on the machine it was built for.
package main

import (
	"fmt"
	"math"
	"strconv"
)

func main() {
	fmt.Println("int is", strconv.IntSize, "bits")
	fmt.Println("largest int:", math.MaxInt)
	fmt.Printf("%T %T %T\n", 42, 4.2, 2i)
}
EOF
quiet numbers 'go mod init example.com/intsize'

block limits
on numbers 'go doc math.MaxInt'

block intsize
on numbers 'go run .'
on numbers 'GOARCH=386 go run .'

lab fresh numbers-wrap
put numbers-wrap/main.go <<'EOF'
package main

import "fmt"

func main() {
	var small int8 = 127
	small++
	fmt.Println(small)

	var count uint = 0
	count--
	fmt.Println(count)
}
EOF
quiet numbers-wrap 'go mod init example.com/wrap'

block wrap
on numbers-wrap 'go run .'

lab fresh numbers-const
put numbers-const/main.go <<'EOF'
package main

import "fmt"

const limit int8 = 127

func main() {
	var small int8 = 128
	next := limit + 1
	fmt.Println(small, next)
}
EOF
quiet numbers-const 'go mod init example.com/const'

block const-overflow
on numbers-const 'go build'

lab fresh numbers-div
put numbers-div/main.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println(7 / 2)
	fmt.Println(-7 / 2)
	fmt.Println(7 % 3)
	fmt.Println(-7 % 3)
	fmt.Println(7.0 / 2)
}
EOF
quiet numbers-div 'go mod init example.com/div'

block div
on numbers-div 'go run .'

lab fresh numbers-zero
put numbers-zero/main.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println(10 / 0)
}
EOF
quiet numbers-zero 'go mod init example.com/zero'

block zero-const
on numbers-zero 'go build'

put numbers-zero/main.go <<'EOF'
package main

import "fmt"

func main() {
	d := 0
	fmt.Println(10 / d)
	fmt.Println("never printed")
}
EOF

block zero-run
on numbers-zero 'go build && ./zero; echo $?'

lab fresh numbers-float
put numbers-float/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
)

func main() {
	fmt.Println(0.1 + 0.2)

	a, b := 0.1, 0.2
	fmt.Println(a + b)
	fmt.Println(a+b == 0.3)
	fmt.Println(math.Abs(a+b-0.3) < 1e-9)

	fmt.Printf("%.20f\n", 0.1)
	fmt.Printf("%x\n", 0.1)
	fmt.Printf("%064b\n", math.Float64bits(0.1))
}
EOF
quiet numbers-float 'go mod init example.com/float'

block float
on numbers-float 'go run .'

lab fresh numbers-nan
put numbers-nan/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
)

func main() {
	zero := 0.0
	fmt.Println(1/zero, -1/zero)

	nan := zero / zero
	fmt.Println(nan, math.Sqrt(-1))
	fmt.Println(nan == nan, nan != nan)
	fmt.Println(math.IsNaN(nan), math.IsInf(1/zero, 1))
	fmt.Println(nan > 1, nan < 1)
}
EOF
quiet numbers-nan 'go mod init example.com/nan'

block nan
on numbers-nan 'go run .'

lab fresh numbers-money
put numbers-money/main.go <<'EOF'
// Command money adds ten coins of ten cents, twice.
package main

import "fmt"

func main() {
	total := 0.0
	for range 10 {
		total += 0.10
	}
	fmt.Println(total, total == 1.0)
	fmt.Printf("%.2f\n", total)

	cents := 0
	for range 10 {
		cents += 10
	}
	fmt.Println(cents, cents == 100)
	fmt.Printf("R$ %d,%02d\n", cents/100, cents%100)
}
EOF
quiet numbers-money 'go mod init example.com/money'

block money
on numbers-money 'go run .'

lab fresh numbers-complex
put numbers-complex/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
	"math/cmplx"
)

func main() {
	z := complex(3, 4)
	fmt.Println(z, real(z), imag(z))
	fmt.Println(cmplx.Abs(z))

	w := 2i
	fmt.Println(w * w)

	fmt.Println(math.Sqrt(-1), cmplx.Sqrt(-1))
	fmt.Printf("%T\n", z)
}
EOF
quiet numbers-complex 'go mod init example.com/complex'

block complex
on numbers-complex 'go run .'
