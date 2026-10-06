#!/usr/bin/env bash
# The terminal sessions quoted in lesson 36 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows; a `go mod init` in each directory, which lesson 4
# showed and this one does not repeat; and notes.txt in ~/panic-close, three
# lines long. ~/panic-must and ~/panic-mustbug differ in one character of the
# pattern; ~/panic-sum and ~/panic-sumbug differ in the first `if` of `number`.
# The server in ~/panic-http is started in the background, given a second to
# listen, and stopped with pkill afterwards; curl is told which local port to
# call from (--local-port) only so that the server's log line reads the same on
# every run. The reads of /usr/local/go/src are the Go 1.27.1 source the lab
# installed. The go1.26.0 toolchain is fetched into the module cache quietly
# first (lesson 2 shows that download), and run from ~ because ~/panic-sum's
# go.mod asks for 1.27.1. Nothing else in the output varies between runs.
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

# ---------------------------------------------------------------- panic
lab fresh panic
put panic/main.go <<'EOF'
// Command panic reads one element past the end of a slice.
package main

import "fmt"

func main() {
	scores := []int{7, 9}
	fmt.Println("scores:", len(scores))
	i := len(scores)
	fmt.Println(scores[i])
	fmt.Println("never printed")
}
EOF
quiet panic 'go mod init example.com/panic'

block panic-run
on panic 'go vet && go run .; echo $?'
on panic 'go build && ./panic; echo $?'

lab fresh panic-must
put panic-must/main.go <<'EOF'
// Command must checks a word against a pattern written in the source
// and against one typed on the command line.
package main

import (
	"fmt"
	"os"
	"regexp"
)

var word = regexp.MustCompile(`^[a-z]+$`)

func main() {
	fmt.Println("word:", word.MatchString(os.Args[1]))
	re, err := regexp.Compile(os.Args[2])
	if err != nil {
		fmt.Println("bad pattern:", err)
		os.Exit(1)
	}
	fmt.Println("pattern:", re.MatchString(os.Args[1]))
}
EOF
quiet panic-must 'go mod init example.com/must'

block must
on panic-must "go build && ./must gopher 'go+'"
on panic-must "./must gopher 'go('; echo \$?"

lab fresh panic-mustbug
put panic-mustbug/main.go <<'EOF'
// Command must checks a word against a pattern written in the source
// and against one typed on the command line.
package main

import (
	"fmt"
	"os"
	"regexp"
)

var word = regexp.MustCompile(`^[a-z+$`)

func main() {
	fmt.Println("word:", word.MatchString(os.Args[1]))
	re, err := regexp.Compile(os.Args[2])
	if err != nil {
		fmt.Println("bad pattern:", err)
		os.Exit(1)
	}
	fmt.Println("pattern:", re.MatchString(os.Args[1]))
}
EOF
quiet panic-mustbug 'go mod init example.com/must'

block mustbug
on panic-mustbug "go build && ./must gopher 'go+'; echo \$?"
on panic-mustbug 'sed -n 309,315p $(go env GOROOT)/src/regexp/regexp.go'

# ---------------------------------------------------------------- defer
lab fresh panic-defer
put panic-defer/main.go <<'EOF'
// Command defer shows when deferred calls run, and in what order.
package main

import "fmt"

func main() {
	for i := range 3 {
		defer fmt.Println("deferred in the loop:", i)
	}

	x := 1
	defer fmt.Println("x when deferred:", x)
	defer func() {
		fmt.Println("x when run:", x)
	}()
	x = 2

	fmt.Println("end of main")
}
EOF
quiet panic-defer 'go mod init example.com/defer'

block defer
on panic-defer 'go run .'

lab fresh panic-close
put panic-close/main.go <<'EOF'
// Command lines counts the lines of each file it is given.
package main

import (
	"bufio"
	"fmt"
	"os"
)

func countLines(name string) (int, error) {
	f, err := os.Open(name)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	n := 0
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

func main() {
	for _, name := range os.Args[1:] {
		n, err := countLines(name)
		if err != nil {
			fmt.Println(err)
			continue
		}
		fmt.Println(name, n)
	}
}
EOF
put panic-close/notes.txt <<'EOF'
buy coffee
call Bia
read lesson 36
EOF
quiet panic-close 'go mod init example.com/lines'

block close
on panic-close 'go build && ./lines notes.txt missing.txt'

lab fresh panic-exit
put panic-exit/main.go <<'EOF'
// Command exit stops in one of two ways.
package main

import (
	"fmt"
	"os"
)

func main() {
	defer fmt.Println("deferred: cleaning up")
	if len(os.Args) > 1 {
		os.Exit(3)
	}
	var prices map[string]int
	prices["pear"] = 3
}
EOF
quiet panic-exit 'go mod init example.com/exit'

block exit
on panic-exit 'go build && ./exit; echo $?'
on panic-exit './exit now; echo $?'
on panic-exit 'go doc os.Exit'
on panic-exit 'go doc log.Fatal'

# ---------------------------------------------------------------- recover
lab fresh panic-sum
put panic-sum/main.go <<'EOF'
// Command sum adds the numbers in a text like "1+2+3".
package main

import (
	"fmt"
	"strconv"
	"strings"
)

// parseError carries a failure out of the helpers. It never leaves Sum.
type parseError struct {
	err error
}

func fail(format string, args ...any) {
	panic(parseError{fmt.Errorf(format, args...)})
}

func number(s string) int {
	if s == "" {
		fail("empty term")
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		fail("%q is not a number", s)
	}
	return n
}

// Sum answers with an error, never with a panic.
func Sum(text string) (total int, err error) {
	defer func() {
		r := recover()
		if r == nil {
			return
		}
		pe, ok := r.(parseError)
		if !ok {
			panic(r)
		}
		total, err = 0, pe.err
	}()
	for _, term := range strings.Split(text, "+") {
		total += number(term)
	}
	return total, nil
}

func main() {
	for _, text := range []string{"1+2+3", "1++3", "1+two"} {
		fmt.Println(Sum(text))
	}
}
EOF
quiet panic-sum 'go mod init example.com/sum'

block sum
on panic-sum 'go vet && go run .'

lab fresh panic-sumbug
put panic-sumbug/main.go <<'EOF'
// Command sum adds the numbers in a text like "1+2+3".
package main

import (
	"fmt"
	"strconv"
	"strings"
)

// parseError carries a failure out of the helpers. It never leaves Sum.
type parseError struct {
	err error
}

func fail(format string, args ...any) {
	panic(parseError{fmt.Errorf(format, args...)})
}

func number(s string) int {
	if s[0] == '-' {
		fail("%s: negative numbers are not allowed", s)
	}
	if s == "" {
		fail("empty term")
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		fail("%q is not a number", s)
	}
	return n
}

// Sum answers with an error, never with a panic.
func Sum(text string) (total int, err error) {
	defer func() {
		r := recover()
		if r == nil {
			return
		}
		pe, ok := r.(parseError)
		if !ok {
			panic(r)
		}
		total, err = 0, pe.err
	}()
	for _, term := range strings.Split(text, "+") {
		total += number(term)
	}
	return total, nil
}

func main() {
	for _, text := range []string{"1+2+3", "1++3", "1+two"} {
		fmt.Println(Sum(text))
	}
}
EOF
quiet panic-sumbug 'go mod init example.com/sum'

block sumbug
on panic-sumbug 'go build && ./sum 2>&1 | head -2'
on panic-sumbug './sum >/dev/null 2>&1; echo $?'

block recover-doc
on panic-sum 'go doc builtin.recover'

block gob
on panic-sum 'sed -n 9,14p $(go env GOROOT)/src/encoding/gob/error.go'
on panic-sum "go list -f '{{.GoFiles}}' encoding/json"
on panic-sum "GOEXPERIMENT=nojsonv2 go list -f '{{.GoFiles}}' encoding/json"
quiet panic-sum 'cd ~ && GOTOOLCHAIN=go1.26.0 go version'
on panic-sum "cd ~ && GOTOOLCHAIN=go1.26.0 go list -f '{{.GoFiles}}' encoding/json"
on panic-sum "grep -n -A10 '^func (e \*encodeState) marshal' \$(go env GOROOT)/src/encoding/json/encode.go"

lab fresh panic-http
put panic-http/main.go <<'EOF'
// Command panic-http answers on two paths, and one of them has a bug.
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	log.SetFlags(0) // no date on each line
	http.HandleFunc("/ok", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	http.HandleFunc("/boom", func(w http.ResponseWriter, r *http.Request) {
		var hits map[string]int
		hits[r.URL.Path]++
		fmt.Fprintln(w, "never sent")
	})
	log.Fatal(http.ListenAndServe("localhost:8036", nil))
}
EOF
quiet panic-http 'go mod init example.com/panic-http'

block http-doc
on panic-http 'go doc net/http.Handler | sed -n 21,26p'

block http
quiet panic-http 'pkill -x panic-http'
on panic-http 'go build && (./panic-http 2>server.log &)'
quiet panic-http 'sleep 1'
on panic-http 'curl -sS --local-port 41036 localhost:8036/boom'
on panic-http 'curl -s localhost:8036/ok'
on panic-http 'head -1 server.log'
on panic-http 'grep panic-http/main.go server.log'
quiet panic-http 'pkill -x panic-http'

lab fresh panic-goroutine
put panic-goroutine/main.go <<'EOF'
// Command goroutine panics somewhere its recover cannot reach.
package main

import (
	"fmt"
	"time"
)

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	go func() {
		panic("in another goroutine")
	}()
	time.Sleep(100 * time.Millisecond)
	fmt.Println("never printed")
}
EOF
quiet panic-goroutine 'go mod init example.com/goroutine'

block goroutine
on panic-goroutine 'go build && ./goroutine 2>/dev/null; echo $?'
on panic-goroutine "./goroutine 2>&1 | grep -E '^(panic|created by)'"

lab fresh panic-overflow
put panic-overflow/main.go <<'EOF'
// Command overflow calls itself until the stack runs out.
package main

import "fmt"

func depth(n int) int {
	return depth(n+1) + 1
}

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	fmt.Println(depth(0))
}
EOF
quiet panic-overflow 'go mod init example.com/overflow'

block overflow
on panic-overflow "go build && ./overflow 2>&1 | grep -E '^(runtime: goroutine|fatal error)'"
on panic-overflow './overflow >/dev/null 2>&1; echo $?'
