#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows. Nothing here varies between runs.
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

# --- methods ----------------------------------------------------------------
lab fresh methods
put methods/main.go <<'EOF'
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func CToF(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

func (c Celsius) ToFahrenheit() Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

type Rect struct {
	W, H float64
}

func (r Rect) Area() float64 {
	return r.W * r.H
}

func main() {
	boil := Celsius(100)
	fmt.Println(CToF(boil), boil.ToFahrenheit())

	r := Rect{W: 3, H: 4}
	fmt.Println(r.Area())
}
EOF
quiet methods 'go mod init example.com/methods'

block methods
on methods 'go run .'

lab fresh methods-nonlocal
put methods-nonlocal/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

type Number = int

func (n int) Double() int {
	return n * 2
}

func (d time.Duration) Days() float64 {
	return d.Hours() / 24
}

func (n Number) Triple() int {
	return n * 3
}

func main() {
	fmt.Println("never printed")
}
EOF
quiet methods-nonlocal 'go mod init example.com/nonlocal'

block nonlocal
on methods-nonlocal 'go build'

lab fresh methods-local
put methods-local/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

type Number int

func (n Number) Double() Number {
	return n * 2
}

type Span time.Duration

func (s Span) Days() float64 {
	return time.Duration(s).Hours() / 24
}

func main() {
	fmt.Println(Number(21).Double())
	fmt.Println(Span(36 * time.Hour).Days())
}
EOF
quiet methods-local 'go mod init example.com/local'

block local
on methods-local 'go run .'

lab fresh methods-span
put methods-span/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

type Span time.Duration

func main() {
	s := Span(36 * time.Hour)
	fmt.Println(s.Hours())
}
EOF
quiet methods-span 'go mod init example.com/span'

block span
on methods-span 'go build'

lab fresh methods-days
put methods-days/main.go <<'EOF'
package main

import (
	"fmt"
	"time"
)

type Weekday int

const (
	Sunday Weekday = iota
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
)

var names = [...]string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

func (d Weekday) String() string {
	return names[d]
}

func main() {
	fmt.Println(Sunday, Monday, Saturday)
	fmt.Printf("%v %s %d\n", Saturday, Saturday, Saturday)
	fmt.Println(Saturday.String() + "!")
	fmt.Println(time.Saturday)
}
EOF
quiet methods-days 'go mod init example.com/days'

block days
on methods-days 'go run .'
on methods-days 'go doc time.Weekday.String'

# --- when-a-receiver --------------------------------------------------------
lab fresh methods-funcs
put methods-funcs/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
)

type Rect struct {
	W, H float64
}

type Circle struct {
	R float64
}

func Area(r Rect) float64 {
	return r.W * r.H
}

func Area(c Circle) float64 {
	return math.Pi * c.R * c.R
}

func main() {
	fmt.Println(Area(Rect{W: 3, H: 4}))
}
EOF
quiet methods-funcs 'go mod init example.com/funcs'

block funcs
on methods-funcs 'go build'

lab fresh methods-shapes
put methods-shapes/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
)

type Rect struct {
	W, H float64
}

type Circle struct {
	R float64
}

func (r Rect) Area() float64 {
	return r.W * r.H
}

func (c Circle) Area() float64 {
	return math.Pi * c.R * c.R
}

func main() {
	fmt.Println(Rect{W: 3, H: 4}.Area())
	fmt.Printf("%.2f\n", Circle{R: 1}.Area())
}
EOF
quiet methods-shapes 'go mod init example.com/shapes'

block shapes
on methods-shapes 'go run .'

block strings
on methods-shapes 'go doc strings | grep -c "^func"'
on methods-shapes 'go doc strings | grep "^type"'
on methods-shapes 'go doc time.Since'

# --- method-values ----------------------------------------------------------
lab fresh methods-values
put methods-values/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

type Rect struct {
	W, H float64
}

func (r Rect) Area() float64 {
	return r.W * r.H
}

type Shift int

func (s Shift) Rotate(r rune) rune {
	if r < 'a' || r > 'z' {
		return r
	}
	return 'a' + (r-'a'+rune(s))%26
}

func main() {
	r := Rect{W: 3, H: 4}
	area := r.Area
	fmt.Printf("%T  %v\n", area, area())
	fmt.Printf("%T  %v\n", Rect.Area, Rect.Area(r))

	r.W = 10
	fmt.Println(area(), r.Area())

	fmt.Println(strings.Map(Shift(13).Rotate, "hello, gopher"))
}
EOF
quiet methods-values 'go mod init example.com/values'

block values
on methods-values 'go run .'
on methods-values 'go doc strings.Map | head -4'

lab fresh methods-embed
put methods-embed/main.go <<'EOF'
package main

import "fmt"

type Person struct {
	Name string
}

func (p Person) Greet() string {
	return "Hello, I am " + p.Name
}

func (p Person) Introduce() string {
	return p.Greet() + "."
}

type Contractor struct {
	Person
	Agency string
}

type Employee struct {
	Person
	Company string
}

func (e Employee) Greet() string {
	return e.Person.Greet() + " from " + e.Company
}

func main() {
	c := Contractor{Person: Person{Name: "Caio"}, Agency: "Temps"}
	e := Employee{Person: Person{Name: "Ana"}, Company: "Acme"}

	fmt.Println(c.Greet())
	fmt.Println(e.Greet())
	fmt.Println(e.Person.Greet())
	fmt.Println(e.Introduce())
}
EOF
quiet methods-embed 'go mod init example.com/embed'

block embed
on methods-embed 'go run .'
