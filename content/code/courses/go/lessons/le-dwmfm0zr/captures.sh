#!/usr/bin/env bash
# The terminal sessions quoted in lesson 39 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the files ana wrote, put below, whose contents the lesson shows.
#   - ~/pkgs-twonames, ~/pkgs-peek and ~/pkgs-cycle start as quiet copies of
#     the module in ~/pkgs, and then get the one file the lesson shows changing.
#   - ~/pkgs-work/wordy is a quiet copy of ~/pkgs too, so that the workspace
#     beside it has a second module to import from.
# Nothing here touches the network: every import is the standard library or a
# package on this disk.
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

# ---------------------------------------------------------------- the module
lab fresh pkgs
put pkgs/go.mod <<'EOF'
module example.com/wordy

go 1.27.1
EOF
put pkgs/text/count.go <<'EOF'
// Package text counts the words in a piece of prose.
package text

import (
	"strings"

	"example.com/wordy/internal/fold"
)

// Counts maps each word to the number of times it appears.
type Counts map[string]int

// Count splits s into words and counts each one, ignoring case.
func Count(s string) Counts {
	c := Counts{}
	for _, w := range strings.Fields(s) {
		if w = fold.Word(w); w != "" {
			c[w]++
		}
	}
	return c
}
EOF
put pkgs/text/top.go <<'EOF'
package text

import (
	"cmp"
	"slices"
)

// Entry is one word and how often it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words, most frequent first.
func (c Counts) Top(n int) []Entry {
	list := c.entries()
	slices.SortFunc(list, byCount)
	return list[:min(n, len(list))]
}

func (c Counts) entries() []Entry {
	list := make([]Entry, 0, len(c))
	for w, n := range c {
		list = append(list, Entry{w, n})
	}
	return list
}

func byCount(a, b Entry) int {
	if d := cmp.Compare(b.Count, a.Count); d != 0 {
		return d
	}
	return cmp.Compare(a.Word, b.Word)
}
EOF
put pkgs/internal/fold/fold.go <<'EOF'
// Package fold puts a word into the form package text compares.
package fold

import (
	"strings"
	"unicode"
)

// Word lower-cases w and trims anything but letters and digits from its ends.
func Word(w string) string {
	return strings.TrimFunc(strings.ToLower(w), func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
}
EOF
put pkgs/cmd/wordcount/main.go <<'EOF'
// Command wordcount prints how many different words a file contains.
package main

import (
	"fmt"
	"os"

	"example.com/wordy/text"
)

func main() {
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println(len(text.Count(string(b))), "different words")
}
EOF
put pkgs/cmd/wordtop/main.go <<'EOF'
// Command wordtop prints the three words a file uses most.
package main

import (
	"fmt"
	"os"

	"example.com/wordy/text"
)

func main() {
	b, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	for _, e := range text.Count(string(b)).Top(3) {
		fmt.Printf("%-6s %d\n", e.Word, e.Count)
	}
}
EOF
put pkgs/notes.txt <<'EOF'
Go is simple. Go is fast, and go builds one binary.
Simple is not the same as easy.
EOF

# ---------------------------------------------------------------- packages
block tree
on pkgs 'find . -type f | sort'
on pkgs 'go run ./cmd/wordcount notes.txt'
on pkgs 'go run ./cmd/wordtop notes.txt'

block list
on pkgs 'go list ./...'
on pkgs 'go list -f "{{.ImportPath}}  {{.Name}}  {{.Dir}}" ./text'

block names
on pkgs 'go list -f "{{.ImportPath}}  {{.Name}}" math/rand/v2 encoding/json'

block imports
on pkgs 'go list -f "{{.ImportPath}}: {{join .Imports \" \"}}" ./...'

block install
on pkgs 'GOBIN=~/pkgs/bin go install ./cmd/... && ls bin'
on pkgs 'ls -d /usr/local/go/src/cmd/go /usr/local/go/src/cmd/gofmt /usr/local/go/src/cmd/vet'
quiet pkgs 'rm -r bin'

lab fresh pkgs-twonames
quiet pkgs-twonames 'cp -r ~/pkgs/. .'
put pkgs-twonames/text/words.go <<'EOF'
package words
EOF

block twonames
on pkgs-twonames 'go build ./...'

# ---------------------------------------------------------------- exported
lab fresh pkgs-peek
quiet pkgs-peek 'cp -r ~/pkgs/. .'
put pkgs-peek/cmd/peek/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/wordy/text"
)

func main() {
	c := text.Count("one two two")
	fmt.Println(c.entries())
	fmt.Println(text.byCount(text.Entry{"a", 1}, text.Entry{"b", 2}))
	var e text.Entry
	fmt.Println(e.word)
}
EOF

block peek
on pkgs-peek 'go build ./cmd/peek'

block doc
on pkgs 'go doc ./text Counts'
on pkgs 'go doc -u ./text Counts'

lab fresh pkgs-json
put pkgs-json/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
)

type Entry struct {
	Word  string `json:"word"`
	count int    `json:"count"`
}

func main() {
	b, err := json.Marshal(Entry{Word: "go", count: 3})
	fmt.Println(string(b), err)

	var e Entry
	err = json.Unmarshal([]byte(`{"word":"go","count":3}`), &e)
	fmt.Printf("%+v %v\n", e, err)
}
EOF
quiet pkgs-json 'go mod init example.com/entry'

block json
on pkgs-json 'go run .'
on pkgs-json 'go vet; echo $?'

# ---------------------------------------------------------------- import rules
lab fresh pkgs-cycle
quiet pkgs-cycle 'cp -r ~/pkgs/. .'
put pkgs-cycle/internal/fold/fold.go <<'EOF'
// Package fold puts a word into the form package text compares.
package fold

import (
	"strings"
	"unicode"

	"example.com/wordy/text"
)

// Common reports whether w is one of the words in common.
func Common(w string, common text.Counts) bool {
	return common[Word(w)] > 0
}

// Word lower-cases w and trims anything but letters and digits from its ends.
func Word(w string) string {
	return strings.TrimFunc(strings.ToLower(w), func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
}
EOF

block cycle
on pkgs-cycle 'go build ./...; echo $?'

lab fresh pkgs-work
quiet pkgs-work 'cp -r ~/pkgs wordy'
put pkgs-work/other/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/wordy/internal/fold"
	"example.com/wordy/text"
)

func main() {
	fmt.Println(len(text.Count("one two two")), fold.Word("Hello!"))
}
EOF
quiet pkgs-work 'cd other && go mod init example.com/other'

block internal
on pkgs-work 'go work init ./wordy ./other'
on pkgs-work 'go run ./other; echo $?'

lab fresh pkgs-rand
put pkgs-rand/main.go <<'EOF'
package main

import (
	"crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(10), len(rand.Text()))
}
EOF
quiet pkgs-rand 'go mod init example.com/dice'

block rand
on pkgs-rand 'go build'

lab fresh pkgs-alias
put pkgs-alias/main.go <<'EOF'
package main

import (
	crand "crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(1), len(crand.Text()))
}
EOF
quiet pkgs-alias 'go mod init example.com/dice'

block alias
on pkgs-alias 'go run .'

lab fresh pkgs-png
put pkgs-png/main.go <<'EOF'
package main

import (
	"fmt"
	"image"
	"os"
)

func main() {
	f, err := os.Open("/usr/local/go/src/image/png/testdata/gray-gradient.png")
	if err != nil {
		fmt.Println(err)
		return
	}
	cfg, format, err := image.DecodeConfig(f)
	f.Close()
	fmt.Printf("%q %dx%d %v\n", format, cfg.Width, cfg.Height, err)
}
EOF
quiet pkgs-png 'go mod init example.com/png'

block png
on pkgs-png 'go run .'
on pkgs-png 'sed -i "s|\"image\"$|&\n\t_ \"image/png\"|" main.go && sed -n 3,8p main.go'
on pkgs-png 'go run .'
on pkgs-png 'grep -n "func init" -A2 /usr/local/go/src/image/png/reader.go'

lab fresh pkgs-init
put pkgs-init/go.mod <<'EOF'
module example.com/order

go 1.27.1
EOF
put pkgs-init/reg/reg.go <<'EOF'
// Package reg keeps a list that other packages add to.
package reg

import "fmt"

var Names []string

func init() {
	fmt.Println("reg: init")
}
EOF
put pkgs-init/main.go <<'EOF'
package main

import (
	"fmt"

	"example.com/order/reg"
)

var greeting = say("main: package variable")

func say(s string) string {
	fmt.Println(s)
	return s
}

func init() {
	reg.Names = append(reg.Names, "main")
	fmt.Println("main: init")
}

func main() {
	fmt.Println("main: main", reg.Names)
}
EOF

block init
on pkgs-init 'go run .'

lab fresh pkgs-dot
put pkgs-dot/main.go <<'EOF'
package main

import (
	"fmt"
	. "strings"
)

func Title(s string) string {
	return ToUpper(s[:1]) + s[1:]
}

func main() {
	fmt.Println(Title("go"), Repeat("!", 3))
}
EOF
quiet pkgs-dot 'go mod init example.com/dot'

block dot
on pkgs-dot 'go run .'
