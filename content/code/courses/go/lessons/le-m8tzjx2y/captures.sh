#!/usr/bin/env bash
# The terminal sessions quoted in lesson 28 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. In any-alias the
# `go` line of go.mod is moved back to 1.17 with `go mod edit`, which is typed
# and shown. Nothing here varies between runs.
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

# ---------------------------------------------------------------- section any
lab fresh any
put any/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	var v any
	fmt.Printf("%-12T %v\n", v, v)

	v = 42
	fmt.Printf("%-12T %v\n", v, v)

	v = "Ana"
	fmt.Printf("%-12T %v\n", v, v)

	v = []int{1, 2, 3}
	fmt.Printf("%-12T %v\n", v, v)

	v = Player{Name: "Ana", Score: 10}
	fmt.Printf("%-12T %v\n", v, v)

	things := []any{42, "Ana", 2.5, true, nil}
	fmt.Println(len(things), things)
}
EOF
quiet any 'go mod init example.com/any'

block any
on any 'go run .'

lab fresh any-alias
put any-alias/main.go <<'EOF'
package main

import "fmt"

func main() {
	var v any = 1
	var w interface{} = "one"
	v = w
	fmt.Printf("%T %T %v\n", &v, &w, v)
}
EOF
quiet any-alias 'go mod init example.com/alias'

block any-alias
on any-alias 'go doc builtin.any'
on any-alias 'go run .'
on any-alias 'go mod edit -go=1.17 && go build'

lab fresh any-slice
put any-slice/main.go <<'EOF'
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	fmt.Println(names...)
}
EOF
quiet any-slice 'go mod init example.com/slice'

block any-slice
on any-slice 'go build'

lab fresh any-slice-fix
put any-slice-fix/main.go <<'EOF'
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	args := make([]any, len(names))
	for i, n := range names {
		args[i] = n
	}
	fmt.Println(args...)
}
EOF
quiet any-slice-fix 'go mod init example.com/slice'

block any-slice-fix
on any-slice-fix 'go run .'

lab fresh any-json
put any-json/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	data := []byte(`{"name": "Ana", "age": 31, "admin": false,
		"tags": ["go", "sql"], "boss": null, "id": 9007199254740993}`)

	var doc map[string]any
	if err := json.Unmarshal(data, &doc); err != nil {
		fmt.Println(err)
		return
	}
	for _, k := range []string{"name", "age", "admin", "tags", "boss", "id"} {
		fmt.Printf("%-6s %-14T %v\n", k, doc[k], doc[k])
	}
}
EOF
quiet any-json 'go mod init example.com/doc'

block any-json
on any-json 'go run .'
on any-json "go doc encoding/json.Unmarshal | grep -A8 'into an interface value'"

lab fresh any-json-number
put any-json-number/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	ID int64 `json:"id"`
}

func main() {
	data := `{"id": 9007199254740993}`

	var doc map[string]any
	dec := json.NewDecoder(strings.NewReader(data))
	dec.UseNumber()
	if err := dec.Decode(&doc); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", doc["id"], doc["id"])

	var u User
	if err := json.Unmarshal([]byte(data), &u); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", u.ID, u.ID)
}
EOF
quiet any-json-number 'go mod init example.com/number'

block any-json-number
on any-json-number 'go run .'

# ---------------------------------------------------------------- section the-cost
lab fresh any-age
put any-age/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var doc map[string]any
	if err := json.Unmarshal([]byte(`{"name": "Ana", "age": 31}`), &doc); err != nil {
		fmt.Println(err)
		return
	}

	age := doc["age"].(float64)
	fmt.Println("next year:", age+1)

	years := doc["age"].(int)
	fmt.Println("next year:", years+1)
}
EOF
quiet any-age 'go mod init example.com/age'

block any-age
on any-age 'go run .'

lab fresh any-ops
put any-ops/main.go <<'EOF'
package main

import "fmt"

func main() {
	var a, b any = 2, 3
	fmt.Println(a + b)

	var s any = "Ana"
	fmt.Println(len(s))

	var n int = a
	fmt.Println(n)
}
EOF
quiet any-ops 'go mod init example.com/ops'

block any-ops
on any-ops 'go build'

lab fresh any-sum
put any-sum/main.go <<'EOF'
package main

import "fmt"

func sum(xs []any) float64 {
	total := 0.0
	for _, x := range xs {
		total += x.(float64)
	}
	return total
}

func main() {
	fmt.Println(sum([]any{1.5, 2.5}))
	fmt.Println(sum([]any{1.5, 2}))
}
EOF
quiet any-sum 'go mod init example.com/sum'

block any-sum
on any-sum 'go vet && go run .'

lab fresh any-sum-typed
put any-sum-typed/main.go <<'EOF'
package main

import "fmt"

func sum(xs []float64) float64 {
	total := 0.0
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(sum([]float64{1.5, 2.5}))
	fmt.Println(sum([]float64{1.5, 2}))
	fmt.Println(sum([]float64{1.5, "2"}))
}
EOF
quiet any-sum-typed 'go mod init example.com/sum'

block any-sum-typed
on any-sum-typed 'go build'

lab fresh any-compare
put any-compare/main.go <<'EOF'
package main

import "fmt"

func main() {
	var a, b any = 1, 1
	fmt.Println(a == b)

	var c, d any = 1, 1.0
	fmt.Println(c == d)

	var e, f any = []int{1}, []int{1}
	fmt.Println(e == f)
}
EOF
quiet any-compare 'go mod init example.com/compare'

block any-compare
on any-compare 'go run .'

# ---------------------------------------------------------------- section nil-inside
lab fresh any-nil
put any-nil/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name string
}

func main() {
	var e any
	var p *Player
	var v any = p

	fmt.Println(e == nil, p == nil, v == nil)
	fmt.Printf("%T %v\n", e, e)
	fmt.Printf("%T %v\n", v, v)
	fmt.Println(v == (*Player)(nil))
}
EOF
quiet any-nil 'go mod init example.com/nil'

block any-nil
on any-nil 'go run .'

lab fresh any-nil-func
put any-nil-func/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
	r := lookup("zoe")
	fmt.Println(r.(*Player).Name)
}
EOF
quiet any-nil-func 'go mod init example.com/lookup'

block any-nil-func
on any-nil-func 'go vet && go run .'

lab fresh any-nil-fix
put any-nil-fix/main.go <<'EOF'
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	if p == nil {
		return nil
	}
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
}
EOF
quiet any-nil-fix 'go mod init example.com/lookup'

block any-nil-fix
on any-nil-fix 'go run .'
