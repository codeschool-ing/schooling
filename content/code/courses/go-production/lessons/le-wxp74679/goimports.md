---
title: The import block, written by goimports
version: 1
---

`gofmt` will sort the lines of an import block, and that is all it does with one. It does not know
that you used `os` without importing it or imported `strings` and never used it; **the compiler
refuses both, and the second refusal surprises people from other languages**, where an unused
import is at most a warning. `goimports` is `gofmt` plus that knowledge. It formats a file the way
`gofmt` does, and then rewrites the import block so it holds exactly what the file uses, grouped
the way Go code conventionally groups it.

It is not part of the toolchain. It lives in the `golang.org/x/tools` module, and `go install`
builds it into `~/go/bin`, which lesson 1 section 02 put on your `PATH`. This course pins the
version, like every tool it installs:

```sh
go install golang.org/x/tools/cmd/goimports@v0.52.0
```

The go command prints a line for each module it downloads, and how many depends on what your module
cache already holds. The binary records what it was built from, which is the reliable check:

```
ana@vm:~/fmt$ go version -m $(command -v goimports) | head -3
/home/ana/go/bin/goimports: go1.27.1
	path	golang.org/x/tools/cmd/goimports
	mod	golang.org/x/tools	v0.52.0	h1:ryxg4U63oaUYk7uOLTF37n43f4qgtGvqV4Ioit1BaEs=
```

## A file with the wrong imports

A second small program for `hits`, in `tools/` beside `genlog`: it reads a log on standard input and
prints the families of `Classes` from section 02, with thousands separators so that a five-digit
count reads at a glance. It is written the way code often is just after an edit, using five packages
and importing one it no longer needs. `tools/classes/main.go`:

```go
// Command classes reads an access log on standard input and prints how many
// requests fell in each family of status codes.
package main

import (
	"strings"
)

func main() {
	s, err := tally.Count(os.Stdin)
	if err != nil {
		fmt.Fprintln(os.Stderr, "classes:", err)
		os.Exit(1)
	}
	p := message.NewPrinter(language.English)
	for _, c := range tally.Classes(s) {
		p.Printf("%s  %7d  %5.1f%%\n", c.Name, c.Requests, 100*c.Share)
	}
}
```

The compiler lists every problem, one per use:

```
ana@vm:~/fmt$ go build ./tools/classes
# example.com/hits/tools/classes
tools/classes/main.go:6:2: "strings" imported and not used
tools/classes/main.go:10:12: undefined: tally
tools/classes/main.go:10:24: undefined: os
tools/classes/main.go:12:3: undefined: fmt
tools/classes/main.go:12:16: undefined: os
tools/classes/main.go:13:3: undefined: os
tools/classes/main.go:15:7: undefined: message
tools/classes/main.go:15:26: undefined: language
tools/classes/main.go:16:20: undefined: tally
```

`message` and `language` come from `golang.org/x/text`, a module outside the standard library, so
the module has to require it before anything can find its packages. `go get` adds the requirement:

```sh
go get golang.org/x/text@v0.43.0
```

```
ana@vm:~/fmt$ cat go.mod
module example.com/hits

go 1.27.1

require golang.org/x/text v0.43.0 // indirect
```

**`// indirect` means no file of the module imports it yet**, which is true for one more command.

## What goimports does with it

`goimports` takes the same `-l`, `-d` and `-w` as `gofmt`, and they mean the same:

```
ana@vm:~/fmt$ goimports -l .
tools/classes/main.go
ana@vm:~/fmt$ goimports -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go
import (
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
)
```

**`strings` is gone, and the five packages the file uses are in.** For each name used and not
imported, `goimports` looks for a package with that name that exports what the file asks of it:
`fmt` and `os` in the standard library, `tally` inside this module, `message` and `language` among
the modules `go.mod` requires. It is a search, and with two candidates of the same name it can pick
the wrong one; read the block it wrote the first time it writes one in a file.

**The block came out in two groups, separated by a blank line**: the standard library first, then
everything else, each group sorted. `goimports` writes that grouping on every run, so a file it
has been through always has it.

## `-local`: your own packages in a group of their own

In the second group, `example.com/hits/internal/tally` sits among packages from another module,
and on a longer list your own packages get lost in it. `-local` takes a prefix of import paths and
moves the matching ones into a third group, after everything else:

```
ana@vm:~/fmt$ goimports -local example.com/hits -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go
import (
	"fmt"
	"os"

	"golang.org/x/text/language"
	"golang.org/x/text/message"

	"example.com/hits/internal/tally"
)
```

**Standard library, then other people's modules, then yours.** The file had already been through
`goimports` once and its block was already in two groups; `-local` split the second one. Pass it
the module path from your `go.mod`, and pass the same one everywhere: a teammate who runs
`goimports` without `-local` merges the third group back into the second, and the two of you take
turns rewriting each other's import blocks. Section 05 puts the flag in one script so nobody has to
remember it.

The program now builds, and `go mod tidy` drops the `// indirect`, because a file imports the
module now:

```
ana@vm:~/fmt$ go build -o classes ./tools/classes && ./classes < access.log
2xx   10,058   50.3%
3xx    2,421   12.1%
4xx    4,998   25.0%
5xx    2,523   12.6%
ana@vm:~/fmt$ go mod tidy && cat go.mod
module example.com/hits

go 1.27.1

require golang.org/x/text v0.43.0
```

The four counts add up to the 20,000 lines of `access.log`, and `2xx` is lesson 1's 7,554 `200`s,
1,256 `201`s and 1,248 `204`s together.

## In an editor

**You will rarely run `goimports` by hand.** `gopls` is the language server behind Go support in VS
Code, and its documentation describes setups for Vim, Neovim, Emacs, Helix, Sublime Text and Zed.
**It does the same work as `goimports`.** It offers an "Organize imports" action that deletes unused
imports, adds missing ones and sorts them, and a `local` setting that its documentation calls "the
equivalent of the `goimports -local` flag". Many editors run both formatting and organising on every save. This lab has no editor, so **none of it
was run here**; what the lesson shows is the command-line tool, which is also what a hook and a CI
job use, and the way to check that an editor did its job.

`gopls` documents one complaint worth knowing before you meet it: removing an unused import on
save is a nuisance when you have commented out the only line that used it for a minute while
debugging, and the import vanishes. Uncomment the line, save again, and it comes back.
