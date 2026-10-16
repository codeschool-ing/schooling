---
title: Choosing the checks, and where vet stops
version: 1
---

Vet has few settings, on purpose: the suite is meant to be run as it ships. **What you can change is
which analyzers run and, for a few of them, what they know about your code.** Every analyzer is a
flag named after it, and the rule for combining them is short: name one or more as `-NAME` and only
those run; turn one off as `-NAME=false` and all the others run.

```
ana@vm:~/vetted$ go vet -printf=false ./report ./notfound; echo $?
0
ana@vm:~/vetted$ go vet -copylocks -lostcancel ./... 2>&1 | sort
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
fetch/main.go:21:2: the cancel function is not used on all paths (possible context leak)
fetch/main.go:23:3: this return statement may be reached without using the cancel var defined on line 21
```

The first line ran everything except `printf` over the two programs whose only bug is a `printf` one,
and passed. The second ran two analyzers over the whole module and found the bugs of `counter` and
`fetch` and nothing else. The output goes through `sort` because **vet checks packages in parallel
and prints each package's findings as it finishes**, so the order changes from one run to the next.

Turning an analyzer off for a whole project is rarely right; the case for it is an analyzer that keeps
reporting one pattern your code uses on purpose, and the first thing to try is usually to rewrite the
pattern. **Vet has no comment that silences one line**, which is deliberate: the precision criterion of
section 02 is what is supposed to make one unnecessary.

## Your own `printf`

Most programs grow a logging helper that takes a format and arguments, and **a format string is
checked only when vet knows the function is a `printf`**. It works most of them out for itself: a
function that passes its `format` and `args...` straight on to `fmt.Sprintf`, `fmt.Printf` or any
other function already known to format is a *printf wrapper*, and its callers are checked like callers
of `fmt.Printf`. `applog/main.go` has two helpers, written two ways:

```go
// Command applog reports through two helpers of its own.
package main

import (
	"fmt"
	"os"
)

// logf writes one line to standard error, after the program's name.
func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "applog: "+format+"\n", args...)
}

// warnf does the same with a label, by formatting the message first.
func warnf(format string, args ...any) {
	msg := fmt.Sprintf(format, args...)
	fmt.Fprintln(os.Stderr, "applog: warning:", msg)
}

func main() {
	logf("served %s in %d ms", "/login")
	warnf("%s took %d ms", 250, "/api/orders")
}
```

```
ana@vm:~/vetted$ go run ./applog
applog: served /login in %!d(MISSING) ms
applog: warning: %!s(int=250) took %!d(string=/api/orders) ms
ana@vm:~/vetted$ go vet ./applog
applog/main.go:22:9: example.com/vetted/applog.warnf format %s has arg 250 of wrong type int
ana@vm:~/vetted$ go vet -printf.funcs=logf ./applog
applog/main.go:21:21: example.com/vetted/applog.logf format %d reads arg #2, but call has 1 arg
applog/main.go:22:9: example.com/vetted/applog.warnf format %s has arg 250 of wrong type int
```

Both calls are wrong, and the plain run shows it. Vet caught only `warnf`. **`logf` builds a new
format by concatenation, so its `format` parameter is never passed on as a format**, and vet's
inference does not follow it. Two fixes are on offer. The flag `-printf.funcs` names extra functions
to treat as formatters, and a name ending in `f` is taken to have a format argument before the rest;
the third command used it and caught the missing argument. **The better fix is the shape `warnf`
already has**: format first with `fmt.Sprintf`, then add the decoration. That keeps working without
a flag that every person and every CI job has to remember to pass.

## What vet will never tell you

Vet's three criteria rule out more than they let in, and knowing what is outside them stops you
reading a clean run as more than it is.

| not vet's job | why | where it is found |
|---|---|---|
| style: names, comment wording, a long function | correct code written differently is not a bug | lesson 8's linters |
| an unused local variable or import | the compiler already refuses it | `go build` |
| an unused function, parameter or exported name | legal, and often deliberate | lesson 8's `staticcheck` |
| most nil dereferences, and most shadowed variables | finding them precisely enough is the hard part | lesson 8, and the tests |
| a data race between goroutines | it happens at run time | lesson 15's race detector |

The fourth row is worth seeing. `load/main.go` reads a name from a file:

```go
// Command load reads a name from a file, or says why it could not.
package main

import (
	"fmt"
	"os"
	"strings"
)

type Config struct {
	Name   string
	Source string
}

func parse(data []byte) (*Config, error) {
	return &Config{Name: strings.TrimSpace(string(data))}, nil
}

func load(path string) (*Config, error) {
	var cfg *Config
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) > 0 {
		cfg, err := parse(data)
		if err != nil {
			return nil, err
		}
		cfg.Source = path
	}
	return cfg, nil
}

func main() {
	cfg, err := load("name.txt")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(cfg.Name, "from", cfg.Source)
}
```

```
ana@vm:~/vetted$ echo hits > name.txt
ana@vm:~/vetted$ go vet ./load; echo $?
0
ana@vm:~/vetted$ go run ./load 2>&1 | head -1
panic: runtime error: invalid memory address or nil pointer dereference
```

Vet passed it and the program crashed. **`cfg, err := parse(data)` declared a second `cfg` inside the
`if`**, filled that one, and let it go at the closing brace, so `load` returned the outer `cfg`, still
nil. Shadowing is legal and usually intended, and telling the accident from the intention is the hard
part: the analyzer that looks for it says in its own documentation that it "generates too many false
positives and is not yet enabled by default". That is the precision criterion, applied.

## A vet that runs other analyzers

The go command can run a different analysis tool in vet's place, with `-vettool`, as long as that
tool is built on the same framework, `golang.org/x/tools/go/analysis`. That analyzer, `shadow`,
lives in that module, outside the suite, and can be installed and asked for on the day you want it.
The `x/tools` version is the one the course pins for lesson 6's `goimports`, which is why `go
install` printed nothing here: the module was already in the cache from lesson 6. On a first install
it lists what it downloads.

```
ana@vm:~/vetted$ go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@v0.52.0
ana@vm:~/vetted$ go vet -vettool=$(command -v shadow) ./load
load/main.go:26:3: declaration of "cfg" shadows declaration at line 20
```

**One line, and it is the bug.** This is the door lesson 8 walks through: `staticcheck` and
`golangci-lint` are collections of analyzers that make different trades from vet's, more checks for a
little more noise, and the framework underneath is the same one.
