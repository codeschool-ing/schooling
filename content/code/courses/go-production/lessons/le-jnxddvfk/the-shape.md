---
title: The shape of a urfave/cli program
version: 1
---

Lesson 2 put Cobra in front of `hits`. This lesson does the same with **urfave/cli**, the other
library Go programs reach for when the flag package stops being enough, and asks what "lighter"
buys and costs. The tool does not change: two subcommands, `count` and `top`, the same flags, the
same output and the same exit codes as lesson 1. **In urfave/cli a whole program is one value, a
`cli.Command`**, with the subcommands as more `cli.Command`s inside it and a function on each that
runs when the command line names it. Nothing is registered at start-up and there is no generator:
you write the tree as a literal and call `Run` on its root.

The version used throughout is v3, at **v3.14.0**. It matters which major version you read about,
because v2 had a separate `cli.App` type for the root and a `*cli.Context` argument in every
function, and most answers on the web still show them. v3 has one type for both and passes a
`context.Context` instead.

## A module of its own

This version lives in `~/cli-hits`, beside lesson 1's `~/hits`, so the two can be measured against
each other in section 05. It reuses lesson 1's counting unchanged: place the `tally` package from
lesson 1 at `internal/tally/tally.go` and `genlog` at `tools/genlog/main.go`, exactly as lesson 1
section 03 and section 02 print them, then make the module with the same name:

```
ana@vm:~/cli-hits$ go mod init example.com/hits
go: creating new go.mod: module example.com/hits
go: to add module requirements and sums:
	go mod tidy
```

The command line is in two files this time. `main.go` holds the tree of commands and nothing else,
which makes it short enough to read in one piece:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\t\"os\"\n\n\t\"github.com/urfave/cli/v3\"\n)\n",
      "note": "One import more than lesson 1's version, and it is the whole library. The package is called `cli`, and the `/v3` at the end of the path is part of the module's name: v1, v2 and v3 are three different modules that can sit in one build."
    },
    {
      "code": "func main() {\n\tcmd := &cli.Command{\n\t\tName:  \"hits\",\n\t\tUsage: \"summarise a web server's access log\",\n\t\tCommands: []*cli.Command{",
      "note": "**The program is a value**: one `cli.Command` for `hits` itself, holding a slice of `cli.Command`s for the subcommands. Nothing is registered and nothing runs until `Run` is called at the bottom."
    },
    {
      "code": "\t\t\t{\n\t\t\t\tName:      \"count\",\n\t\t\t\tUsage:     \"requests per status code\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags:     []cli.Flag{jsonFlag()},\n\t\t\t\tAction:    count,\n\t\t\t},",
      "note": "A subcommand is the same type as the root. `ArgsUsage` is only text for the help screen; `Flags` lists what this command accepts, and `Action` is the function that runs when the command line names it."
    },
    {
      "code": "\t\t\t{\n\t\t\t\tName:      \"top\",\n\t\t\t\tUsage:     \"the paths with the most requests\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags: []cli.Flag{\n\t\t\t\t\t&cli.IntFlag{\n\t\t\t\t\t\tName:      \"n\",\n\t\t\t\t\t\tAliases:   []string{\"limit\"},\n\t\t\t\t\t\tValue:     3,\n\t\t\t\t\t\tUsage:     \"how many paths to show\",\n\t\t\t\t\t\tSources:   cli.EnvVars(\"HITS_TOP\"),\n\t\t\t\t\t\tValidator: atLeastOne,\n\t\t\t\t\t},\n\t\t\t\t\tjsonFlag(),\n\t\t\t\t},\n\t\t\t\tAction: top,\n\t\t\t},\n\t\t},\n\t}",
      "note": "`top` declares `-n` with four things lesson 1 had to write by hand or did without: a second name, an environment variable to read when the flag is absent, a check on the value, and the default printed in the help. Section 03 runs each one."
    },
    {
      "code": "\tif err := cmd.Run(context.Background(), os.Args); err != nil {\n\t\tfmt.Fprintf(os.Stderr, \"hits: %v\\n\", err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "**`Run` takes the whole of `os.Args`, program name included**, and a `context.Context` that it passes to every Action. This is the shape the library's own README shows, and section 04 is about what it gets wrong."
    },
    {
      "code": "// jsonFlag is a function rather than a variable because a flag holds the\n// value it parsed, so two commands must not share one.\nfunc jsonFlag() cli.Flag {\n\treturn &cli.BoolFlag{Name: \"json\", Usage: \"print JSON instead of a table\"}\n}\n",
      "note": "Both commands take `-json`. A flag in this library is a struct that keeps the value it parsed, so each command gets a fresh one from a function instead of sharing a variable."
    },
    {
      "code": "func atLeastOne(n int) error {\n\tif n < 1 {\n\t\treturn fmt.Errorf(\"must be at least 1, got %d\", n)\n\t}\n\treturn nil\n}",
      "note": "The `Validator` of `-n`. It sees the parsed `int`, after the library has refused anything that is not a number."
    }
  ]
}
```

The two Actions and the function they share go in `report.go`, beside it. They do what lesson 1's
`count`, `top` and `summarise` did, and differ in where they get things: **every Action receives
the `*cli.Command` it belongs to**, and asks it for the flags by name, for the arguments left over
and for the streams to read and write. Save `report.go`:

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"maps"
	"os"
	"slices"
	"text/tabwriter"

	"github.com/urfave/cli/v3"

	"example.com/hits/internal/tally"
)

// count and top are the two Actions. Each receives the command it belongs
// to, which holds the parsed flags, the arguments left over and the streams.
func count(ctx context.Context, cmd *cli.Command) error {
	s, err := summarise(cmd)
	if err != nil {
		return err
	}
	if cmd.Bool("json") {
		return json.NewEncoder(cmd.Writer).Encode(s.ByStatus)
	}
	tw := tabwriter.NewWriter(cmd.Writer, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, "status\trequests")
	for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
		fmt.Fprintf(tw, "%d\t%d\n", status, s.ByStatus[status])
	}
	return tw.Flush()
}

func top(ctx context.Context, cmd *cli.Command) error {
	s, err := summarise(cmd)
	if err != nil {
		return err
	}
	rows := tally.Top(s, cmd.Int("n"))
	if cmd.Bool("json") {
		return json.NewEncoder(cmd.Writer).Encode(rows)
	}
	tw := tabwriter.NewWriter(cmd.Writer, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, "path\trequests")
	for _, r := range rows {
		fmt.Fprintf(tw, "%s\t%d\n", r.Path, r.Hits)
	}
	return tw.Flush()
}

// summarise counts the file named on the command line, or standard input.
// Its errors carry the exit code lesson 1 gave them: 2 for a mistake in the
// call, 1 for a run that failed.
func summarise(cmd *cli.Command) (tally.Summary, error) {
	args := cmd.Args()
	in := cmd.Reader
	switch {
	case args.Len() > 1:
		return tally.Summary{}, cli.Exit(fmt.Sprintf("hits: one file at most, got %d", args.Len()), 2)
	case args.Len() == 1 && args.First() != "-":
		f, err := os.Open(args.First())
		if err != nil {
			return tally.Summary{}, cli.Exit("hits: "+err.Error(), 1)
		}
		defer f.Close()
		in = f
	}
	s, err := tally.Count(in)
	if err != nil {
		return s, cli.Exit("hits: "+err.Error(), 1)
	}
	return s, nil
}
```

Compare `summarise` with lesson 1's. There, it returned an exit code beside the summary, because
nothing else in the program knew what 1 and 2 meant. Here **an error can carry its own exit
code**: `cli.Exit` wraps a message and a number into a value of type `cli.ExitCoder`, which is an
`error` with an `ExitCode` method, and whoever ends up holding the error can ask it which code it
meant. Section 04 is about who that is.

## Fetching the library

With both files saved, the imports name a module the build does not have yet. `go get` fetches it at
the version you name and records it in `go.mod`; `go mod tidy` then reads the imports and settles
the file:

```
ana@vm:~/cli-hits$ go get github.com/urfave/cli/v3@v3.14.0
go: downloading github.com/urfave/cli/v3 v3.14.0
go: added github.com/urfave/cli/v3 v3.14.0
ana@vm:~/cli-hits$ go mod tidy && cat go.mod
go: downloading github.com/stretchr/testify v1.12.1
go: downloading go.yaml.in/yaml/v3 v3.0.5
module example.com/hits

go 1.27.1

require github.com/urfave/cli/v3 v3.14.0
```

**`go.mod` gained one line, `require github.com/urfave/cli/v3 v3.14.0`**, and that is the library's
whole footprint in the build: it depends on nothing outside the standard library. `tidy` still
downloaded two more modules, `testify` and `yaml`, because those are what urfave/cli's own tests
import and `tidy` checks the tests of what you depend on. Section 05 shows that neither of them is
compiled into `hits`. `go-concurrency` lesson 25 covers testing; the module proxy that served the
download is the one `go` lesson 3 set up.

## The same answers

Built, and asked lesson 1's two questions:

```
ana@vm:~/cli-hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./report.go
./tools/genlog/main.go
ana@vm:~/cli-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
6257727 bytes  hits
ana@vm:~/cli-hits$ ./hits count access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
ana@vm:~/cli-hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
```

**The counts match lesson 1 section 03 line for line**, because the counting is the same package
reading the same 20,000 lines; only the code that reads the command line changed. The binary is
another matter. **6,257,727 bytes against lesson 1's 4,031,903**: the library and what it pulls
from the standard library added about 2.2 MB to a program that does exactly the same work. Section
05 puts that beside Cobra's number, and it does not come out the way the word "lighter" suggests.
