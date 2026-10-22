---
title: Subcommands, each with flags of its own
version: 1
---

`go build -o bin/ ./...` and `go test -race` are one program, `go`, whose first word chooses a
subcommand, and each subcommand has flags of its own. **The package-level functions of this lesson's
first two sections all work on one hidden `FlagSet`, `flag.CommandLine`; a subcommand is a
`FlagSet` you make yourself** with `flag.NewFlagSet` and parse from the words after its name.

A small tool with two subcommands, saved as `tool/main.go`:

```go
// Command tool has two subcommands, each with flags of its own.
package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: tool add|list [flags]")
		os.Exit(2)
	}
	switch os.Args[1] {
	case "add":
		fs := flag.NewFlagSet("add", flag.ExitOnError)
		tag := fs.String("tag", "", "tag for the note")
		fs.Parse(os.Args[2:])
		fmt.Printf("add %q tagged %q\n", fs.Args(), *tag)
	case "list":
		fs := flag.NewFlagSet("list", flag.ExitOnError)
		limit := fs.Int("limit", 10, "how many notes to show")
		fs.Parse(os.Args[2:])
		fmt.Println("list, at most", *limit)
	default:
		fmt.Fprintf(os.Stderr, "tool: unknown command %q\n", os.Args[1])
		os.Exit(2)
	}
}
```

`os.Args[0]` is the program's name and `os.Args[1]` the subcommand, so each case parses
`os.Args[2:]`, everything after it. The two `FlagSet`s know nothing of each other: `-tag` belongs
to `add` and `-limit` to `list`.

```
ana@vm:~/flags$ bin/tool add -tag work buy milk
add ["buy" "milk"] tagged "work"
ana@vm:~/flags$ bin/tool list -limit 3
list, at most 3
ana@vm:~/flags$ bin/tool list -tag x; echo $?
flag provided but not defined: -tag
Usage of list:
  -limit int
    	how many notes to show (default 10)
2
```

**A flag given to the wrong subcommand is refused by that subcommand**, with its own usage text,
which names only its own flags. `flag.ExitOnError` is what makes the refusal end the program with
status 2, as the package-level functions do. The other two choices are `flag.ContinueOnError`,
where `Parse` returns the error and the program decides, and `flag.PanicOnError`. A program that
parses more than once, or a test that checks the error, wants `ContinueOnError`.

The cases the `FlagSet`s never see, an unknown subcommand and none at all, are the program's own,
and it follows the same convention:

```
ana@vm:~/flags$ bin/tool remove; echo $?
tool: unknown command "remove"
2
ana@vm:~/flags$ bin/tool; echo $?
usage: tool add|list [flags]
2
```

**Status 2 and a line on standard error** is what a shell script expects from a tool called
wrongly, whatever the language it was written in. Writing that line to standard error rather than
standard output keeps it out of a pipe that was meant for the tool's real output.

Past two or three subcommands, with help for each and flags shared between them, a third-party
library starts to earn its download. This course keeps to the standard library, and what is above
is what those libraries are built on.
