#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of go, as a script that produces them.
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
# lesson 4 showed and this lesson does not repeat. Nothing in this lesson's
# output varies between runs.
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

# ---- the-difference
lab fresh receivers
put receivers/main.go <<'EOF'
package main

import "fmt"

type Counter struct {
	n int
}

func (c Counter) IncByValue() {
	c.n++
	fmt.Println("  inside IncByValue:", c.n)
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	var c Counter
	c.IncByValue()
	c.IncByValue()
	fmt.Println("after IncByValue:", c.n)

	c.Inc()
	c.Inc()
	fmt.Println("after Inc:", c.n)

	p := &c
	p.IncByValue()
	fmt.Println("after p.IncByValue:", c.n)

	fmt.Printf("%T\n%T\n", Counter.IncByValue, (*Counter).Inc)
}
EOF
quiet receivers 'go mod init example.com/receivers'

block copy
on receivers 'go run .'

lab fresh receivers-addr
put receivers-addr/main.go <<'EOF'
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]Counter{"ana": {}}
	byName["ana"].Inc()

	Counter{}.Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(list)
}
EOF
quiet receivers-addr 'go mod init example.com/addr'

block addr
on receivers-addr 'go build'

lab fresh receivers-addr-fix
put receivers-addr-fix/main.go <<'EOF'
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]*Counter{"ana": {}}
	byName["ana"].Inc()
	byName["ana"].Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(byName["ana"].n, list)
}
EOF
quiet receivers-addr-fix 'go mod init example.com/addr'

block addr-fix
on receivers-addr-fix 'go run .'

# ---- method-sets
lab fresh receivers-print
put receivers-print/main.go <<'EOF'
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(price.String())
}
EOF
quiet receivers-print 'go mod init example.com/print'

block print
on receivers-print 'go run .'
on receivers-print 'go vet; echo $?'

block stringer-doc
on receivers-print 'go doc fmt.Stringer'

lab fresh receivers-iface
put receivers-iface/main.go <<'EOF'
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(s)
}
EOF
quiet receivers-iface 'go mod init example.com/iface'

block iface
on receivers-iface 'go build'

lab fresh receivers-value
put receivers-value/main.go <<'EOF'
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(s)
}
EOF
quiet receivers-value 'go mod init example.com/value'

block value
on receivers-value 'go run .'

# ---- choosing
lab fresh receivers-lock
put receivers-lock/main.go <<'EOF'
package main

import (
	"fmt"
	"sync"
)

type Stats struct {
	mu   sync.Mutex
	hits int
}

func (s *Stats) Hit() {
	s.mu.Lock()
	s.hits++
	s.mu.Unlock()
}

func (s Stats) Hits() int {
	s.mu.Lock()
	n := s.hits
	s.mu.Unlock()
	return n
}

func main() {
	var s Stats
	s.Hit()
	s.Hit()
	fmt.Println(s.Hits())
}
EOF
quiet receivers-lock 'go mod init example.com/stats'

block lock
on receivers-lock 'go run .'
on receivers-lock 'go vet; echo $?'

block time-doc
on receivers 'go doc time.Time | head -10'
on receivers 'go doc -all time | grep -c "^func (t Time)"'
on receivers 'go doc -all time | grep "^func (t \*Time)"'

block builder-doc
on receivers 'go doc strings.Builder'
