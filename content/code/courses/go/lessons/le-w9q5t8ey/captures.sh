#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of go, as a script that produces them.
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

# --- section embedding -----------------------------------------------------------

module embed
put embed/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: "Acme",
	}
	fmt.Println(e.Name, e.Person.Name)
	fmt.Println(e.Email)

	e.Name = "Ana Lima"
	fmt.Println(e.Person.Name)

	fmt.Printf("%+v\n", e)
}
EOF

block embed
on embed 'go run .'

module embed-literal
put embed-literal/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	fmt.Printf("%+v\n", e)
}
EOF

block literal
on embed-literal 'go run .'
on embed-literal 'go mod edit -go=1.26'
on embed-literal 'go run .'

module embed-mix
put embed-mix/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func main() {
	e := Employee{Person: Person{Name: "Ana"}, Email: "ana@example.com"}
	fmt.Printf("%+v\n", e)
}
EOF

block mix
on embed-mix 'go run .'

# --- section not-inheritance -----------------------------------------------------

module embed-notis
put embed-notis/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func greet(p Person) {
	fmt.Println("Hello,", p.Name)
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e)
}
EOF

block notis
on embed-notis 'go run .'

module embed-part
put embed-part/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func greet(p Person) {
	fmt.Println("Hello,", p.Name)
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e.Person)

	c := e
	c.Name = "Bia"
	fmt.Println(e.Name, c.Name)
}
EOF

block part
on embed-part 'go run .'

# --- section conflicts -----------------------------------------------------------

module embed-clash
put embed-clash/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company
	Email string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	fmt.Println(e.Email)
	fmt.Println(e.Person.Email, e.Company.Email)
	fmt.Println(e.Name)
}
EOF

block clash
on embed-clash 'go run .'

module embed-depth
put embed-depth/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company
	Email string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	fmt.Println(e.Email)
	fmt.Println(e.Person.Email, e.Company.Email)
	fmt.Println(e.Person.Name, e.Company.Name)
}
EOF

block depth
on embed-depth 'go run .'

module embed-json
put embed-json/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company
	Email string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	b, err := json.Marshal(e)
	fmt.Println(string(b), err)
}
EOF

block json
on embed-json 'go run .'
on embed-json 'go vet; echo $?'
on embed-json "go doc encoding/json.Marshal | grep -A1 'Otherwise there are'"

module embed-json-tag
put embed-json-tag/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company `json:"company"`
	Email   string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	b, err := json.Marshal(e)
	fmt.Println(string(b), err)
}
EOF

block json-tag
on embed-json-tag 'go run .'
