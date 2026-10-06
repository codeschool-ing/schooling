#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of go, as a script that produces them.
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
# between runs: the capacities are what go1.27.1's compiler and runtime choose,
# and the lesson quotes them as this script printed them.
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

# --- len-and-cap ------------------------------------------------------------
lab fresh slices
put slices/main.go <<'EOF'
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid, len(mid), cap(mid))

	more := mid[:5]
	fmt.Println(more, len(more), cap(more))

	fmt.Println(mid[3])
}
EOF
quiet slices 'go mod init example.com/slices'

block len-cap
on slices 'go run .'

lab fresh slices-cap
put slices-cap/main.go <<'EOF'
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid[:6])
}
EOF
quiet slices-cap 'go mod init example.com/slicescap'

block past-cap
on slices-cap 'go run .'

# --- growth -----------------------------------------------------------------
lab fresh slices-grow
put slices-grow/main.go <<'EOF'
package main

import "fmt"

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
}
EOF
quiet slices-grow 'go mod init example.com/grow'

block append-doc
on slices-grow 'go doc builtin.append'

block grow
on slices-grow 'go run .'

block grow-src
on slices-grow 'grep -n "^func nextslicecap" -A 15 /usr/local/go/src/runtime/slice.go'

block size-classes
on slices-grow 'sed -n "6p;53,55p" /usr/local/go/src/internal/runtime/gc/sizeclasses.go'

lab fresh slices-grow-kept
put slices-grow-kept/main.go <<'EOF'
package main

import "fmt"

var kept []int

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
	kept = s
}
EOF
quiet slices-grow-kept 'go mod init example.com/kept'

block grow-kept
on slices-grow-kept 'go run . | head -6'

# --- make -------------------------------------------------------------------
lab fresh slices-make-doc

block make-doc
on slices-make-doc 'go doc builtin.make | head -15'

lab fresh slices-make
put slices-make/main.go <<'EOF'
package main

import "fmt"

func main() {
	var grown []int
	arrays, copied := 0, 0
	for i := 0; i < 2000; i++ {
		if len(grown) == cap(grown) {
			arrays++
			copied += len(grown)
		}
		grown = append(grown, i)
	}
	fmt.Println("append alone:", arrays, "new arrays,", copied, "elements copied")

	sized := make([]int, 0, 2000)
	arrays, copied = 0, 0
	for i := 0; i < 2000; i++ {
		if len(sized) == cap(sized) {
			arrays++
			copied += len(sized)
		}
		sized = append(sized, i)
	}
	fmt.Println("make first:  ", arrays, "new arrays,", copied, "elements copied")
}
EOF
quiet slices-make 'go mod init example.com/make'

block make
on slices-make 'go run .'

lab fresh slices-zeros
put slices-zeros/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

func main() {
	names := []string{"ana", "bia", "caio"}
	upper := make([]string, len(names))
	for i := 0; i < len(names); i++ {
		upper = append(upper, strings.ToUpper(names[i]))
	}
	fmt.Println(len(upper), upper)
	fmt.Printf("%q\n", upper)
}
EOF
quiet slices-zeros 'go mod init example.com/zeros'

block zeros
on slices-zeros 'go run .'

lab fresh slices-swap
put slices-swap/main.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println(make([]int, 10, 3))
}
EOF
quiet slices-swap 'go mod init example.com/swap'

block swap
on slices-swap 'go run .'

lab fresh slices-nil
put slices-nil/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var none []string
	empty := []string{}
	fmt.Println(none, empty)
	fmt.Println(len(none), len(empty))
	fmt.Println(none == nil, empty == nil)

	a, _ := json.Marshal(none)
	b, _ := json.Marshal(empty)
	fmt.Println(string(a), string(b))

	none = append(none, "ana")
	fmt.Println(none, len(none))
}
EOF
quiet slices-nil 'go mod init example.com/nil'

block nil
on slices-nil 'go run .'

# --- aliasing ---------------------------------------------------------------
lab fresh slices-alias
put slices-alias/main.go <<'EOF'
package main

import (
	"fmt"
	"slices"
)

func main() {
	nums := []int{1, 2, 3, 4, 5}
	head := nums[:2]
	head = append(head, 99)
	fmt.Println(nums, head)

	nums = []int{1, 2, 3, 4, 5}
	head = nums[:2:2]
	fmt.Println(len(head), cap(head))
	head = append(head, 99)
	fmt.Println(nums, head)

	nums = []int{1, 2, 3, 4, 5}
	head = slices.Clone(nums[:2])
	head = append(head, 99)
	fmt.Println(nums, head)
}
EOF
quiet slices-alias 'go mod init example.com/alias'

block alias
on slices-alias 'go run .'

lab fresh slices-path
put slices-path/main.go <<'EOF'
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
EOF
quiet slices-path 'go mod init example.com/path'

block path
on slices-path 'go run .'

put slices-path/main.go <<'EOF'
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")
	path = path[:len(path):len(path)]

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
EOF

block path-fixed
on slices-path 'go run .'
