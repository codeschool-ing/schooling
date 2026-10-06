#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of go, as a script that produces them.
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
# lesson 4 showed and this one does not repeat. The one exception is
# ~/structs-v2old, whose go.mod is written by hand with `go 1.26.0` so that the
# go1.26.0 toolchain of lesson 2 will build it; GOTOOLCHAIN=go1.26.0 takes that
# toolchain from the module cache, or downloads it from the module proxy the
# first time. Nothing in the output varies between runs.
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

# --- structs ----------------------------------------------------------------
lab fresh structs
put structs/main.go <<'EOF'
package main

import "fmt"

type Point struct {
	X, Y int
}

type Book struct {
	Title  string
	Author string
	Pages  int
	Tags   []string
}

func main() {
	p := Point{X: 3, Y: 4}
	q := Point{3, 4}
	var origin Point
	fmt.Println(p, q, origin, p == q)

	p.X = 10
	fmt.Println(p.X, p, p == q)

	b := Book{Title: "Dom Casmurro", Author: "Machado de Assis"}
	fmt.Printf("%v\n%+v\n", b, b)
}
EOF
quiet structs 'go mod init example.com/structs'

block basics
on structs 'go run .'

lab fresh structs-eq
put structs-eq/main.go <<'EOF'
package main

import "fmt"

type Book struct {
	Title string
	Tags  []string
}

func main() {
	a := Book{Title: "Dom Casmurro"}
	b := Book{Title: "Dom Casmurro"}
	fmt.Println(a == b)
}
EOF
quiet structs-eq 'go mod init example.com/eq'

block eq
on structs-eq 'go run .'

lab fresh structs-key
put structs-key/main.go <<'EOF'
package main

import "fmt"

type Point struct {
	X, Y int
}

func main() {
	path := []Point{{0, 0}, {0, 1}, {1, 1}, {0, 1}, {0, 0}, {0, 1}}
	visits := map[Point]int{}
	for i := 0; i < len(path); i++ {
		visits[path[i]]++
	}
	fmt.Println(visits)
	fmt.Println(visits[Point{X: 0, Y: 1}], visits[Point{X: 5, Y: 5}])
}
EOF
quiet structs-key 'go mod init example.com/key'

block key
on structs-key 'go run .'

lab fresh structs-unkeyed
put structs-unkeyed/main.go <<'EOF'
package main

import (
	"fmt"
	"net"
)

func main() {
	addr := net.TCPAddr{net.IPv4(127, 0, 0, 1), 8080, ""}
	fmt.Println(addr.String())
}
EOF
quiet structs-unkeyed 'go mod init example.com/unkeyed'

block unkeyed
on structs-unkeyed 'go run .'
on structs-unkeyed 'go vet; echo $?'

lab fresh structs-anon
put structs-anon/main.go <<'EOF'
package main

import "fmt"

func main() {
	origin := struct {
		Lat, Lon float64
	}{-23.55, -46.63}
	fmt.Printf("%+v\n", origin)

	cases := []struct {
		name string
		want int
	}{
		{"ana", 3},
		{"bruno", 5},
		{"jo", 3},
	}
	for i := 0; i < len(cases); i++ {
		got := len(cases[i].name)
		fmt.Println(cases[i].name, got, got == cases[i].want)
	}
}
EOF
quiet structs-anon 'go mod init example.com/anon'

block anon
on structs-anon 'go run .'

# --- json-out ---------------------------------------------------------------
lab fresh structs-json-plain
put structs-json-plain/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name     string
	Email    string
	Password string
	Tags     []string
	age      int
}

func main() {
	u := User{Name: "Ana", Password: "hunter2", age: 31}
	b, err := json.Marshal(u)
	fmt.Println(string(b), err)
}
EOF
quiet structs-json-plain 'go mod init example.com/plain'

block plain
on structs-json-plain 'go run .'

lab fresh structs-json
put structs-json/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name     string   `json:"name"`
	Email    string   `json:"email,omitempty"`
	Password string   `json:"-"`
	Tags     []string `json:"tags"`
	age      int
}

func main() {
	u := User{Name: "Ana", Password: "hunter2", age: 31}
	b, err := json.Marshal(u)
	fmt.Println(string(b), err)

	u.Email = "ana@example.com"
	u.Tags = []string{"go", "sql"}
	b, err = json.MarshalIndent(u, "", "  ")
	fmt.Println(string(b), err)
}
EOF
quiet structs-json 'go mod init example.com/json'

block tags
on structs-json 'go run .'

lab fresh structs-tags-bad
put structs-tags-bad/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string `json: "name"`
	Email string `json:"email, omitempty"`
}

func main() {
	b, _ := json.Marshal(User{Name: "Ana"})
	fmt.Println(string(b))
}
EOF
quiet structs-tags-bad 'go mod init example.com/bad'

block tags-bad
on structs-tags-bad 'go run .'
on structs-tags-bad 'go vet; echo $?'

lab fresh structs-omitzero
put structs-omitzero/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Event struct {
	Name    string    `json:"name"`
	Retries int       `json:"retries,omitempty"`
	Started time.Time `json:"started,omitempty"`
	Ended   time.Time `json:"ended,omitzero"`
}

func main() {
	b, _ := json.Marshal(Event{Name: "deploy"})
	fmt.Println(string(b))
}
EOF
quiet structs-omitzero 'go mod init example.com/omitzero'

block omitzero
on structs-omitzero 'go run .'

# --- json-in ----------------------------------------------------------------
lab fresh structs-in
put structs-in/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia", "tags": ["go", "sql"], "nickname": "b"}`)
	var u User
	err := json.Unmarshal(data, &u)
	fmt.Printf("%+v %v\n", u, err)
}
EOF
quiet structs-in 'go mod init example.com/in'

block in
on structs-in 'go run .'

lab fresh structs-in-bad
put structs-in-bad/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name string `json:"name"`
}

func main() {
	var u User
	fmt.Println(json.Unmarshal([]byte(`{"name": 42}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia",}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia"}`), u))
	fmt.Printf("%+v\n", u)
}
EOF
quiet structs-in-bad 'go mod init example.com/inbad'

block in-bad
on structs-in-bad 'go run .'
on structs-in-bad 'go vet; echo $?'

lab fresh structs-strict
put structs-strict/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := `{"name": "Bia", "emial": "bia@example.com"}`

	var loose User
	fmt.Println(json.Unmarshal([]byte(data), &loose))
	fmt.Printf("%+v\n", loose)

	var strict User
	dec := json.NewDecoder(strings.NewReader(data))
	dec.DisallowUnknownFields()
	fmt.Println(dec.Decode(&strict))
}
EOF
quiet structs-strict 'go mod init example.com/strict'

block strict
on structs-strict 'go run .'

lab fresh structs-v2
put structs-v2/main.go <<'EOF'
package main

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"fmt"
)

type User struct {
	Name string   `json:"name"`
	Tags []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia"}`)
	var a, b User
	fmt.Println(json.Unmarshal(data, &a), jsonv2.Unmarshal(data, &b))
	fmt.Printf("%+v\n%+v\n", a, b)

	out1, _ := json.Marshal(a)
	out2, _ := jsonv2.Marshal(a)
	fmt.Println(string(out1))
	fmt.Println(string(out2))
}
EOF
quiet structs-v2 'go mod init example.com/v2'

block v2
on structs-v2 'go run .'
on structs-v2 'go doc encoding/json | sed -n 13,15p'

lab fresh structs-v2old
put structs-v2old/main.go <<'EOF'
package main

import (
	jsonv2 "encoding/json/v2"
	"fmt"
)

func main() {
	b, _ := jsonv2.Marshal([]string(nil))
	fmt.Println(string(b))
}
EOF
put structs-v2old/go.mod <<'EOF'
module example.com/v2old

go 1.26.0
EOF

block v2-old
on structs-v2old 'go run .'
on structs-v2old 'GOTOOLCHAIN=go1.26.0 go run .'
on structs-v2old 'GOTOOLCHAIN=go1.26.0 GOEXPERIMENT=jsonv2 go run .'
