#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows. The timings differ on every run; the lesson
# quotes one run of this script.
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

lab fresh hello
put hello/hello.go <<'EOF'
// Command hello prints a greeting.
package main

import "fmt"

func main() {
	fmt.Println("Hello, Go")
}
EOF

block run-file
on hello 'go run hello.go'

block mod-init
on hello 'go mod init example.com/hello'
on hello 'cat go.mod'
on hello 'go run .'

block build
on hello 'go build'
on hello 'wc -c go.mod hello.go hello'
on hello './hello'
on hello 'file hello'

block build-o
on hello 'go build -o greet .'
on hello './greet'

block cache
on hello 'go clean -cache'
on hello 'time go run .'
on hello 'time go run .'

block install
on hello 'go install'
on hello 'ls ~/go/bin'
on hello 'cd ~ && hello'

block doc-println
on hello 'go doc fmt.Println'

block doc-fields
on hello 'go doc strings.Fields'

block doc-own
on hello 'go doc'

block doc-pkg
on hello 'go doc strings | head -12'

lab fresh tidy
put tidy/main.go <<'EOF'
package main
import "fmt"
func main(){
    name:="Ana"
  fmt.Println( "Hello,",name )
}
EOF
quiet tidy 'go mod init example.com/tidy'

block gofmt
on tidy 'gofmt -l .'
on tidy 'gofmt -d main.go'
on tidy 'go fmt'
on tidy 'cat main.go'

lab fresh vet
put vet/main.go <<'EOF'
package main

import "fmt"

func main() {
	name := "Ana"
	fmt.Printf("Hello, %d\n", name)
}
EOF
quiet vet 'go mod init example.com/vet'

block vet
on vet 'go run .'
on vet 'go vet; echo $?'

lab fresh unused
put unused/main.go <<'EOF'
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("Hello, Go")
}
EOF
quiet unused 'go mod init example.com/unused'

block unused
on unused 'go run .; echo $?'
