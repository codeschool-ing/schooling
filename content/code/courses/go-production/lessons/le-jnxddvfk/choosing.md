---
title: Lighter in what? Three versions measured
version: 1
---

urfave/cli is usually described as the lighter alternative to Cobra, and the word is rarely
unpacked. **Light can mean a smaller binary, fewer modules to trust and update, or less code of your own**,
and those are three different measurements that need not agree. This section takes all three for
the same `hits`, built three ways on the same machine: the standard library version of lesson 1, the
urfave/cli version of sections 02 to 04, and a Cobra version.

## The three programs

Lesson 1's version goes in a directory of its own, `~/std-hits`, with its `main.go` and the `tally`
package placed exactly as lesson 1 section 04 prints them. The urfave/cli version is `~/cli-hits` as
section 04 left it. For Cobra, lesson 2 explains the pieces; the program below is only here to be
measured, and it keeps the same output and the same exit codes, with `-n` checked for at least 1.
In `~/cobra-cmp`, beside the same `internal/tally/tally.go`, with a module made by
`go mod init example.com/hits`, save `main.go`:

```go
// Command hits summarises a web server's access log, on Cobra.
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"os"
	"slices"
	"text/tabwriter"

	"github.com/spf13/cobra"

	"example.com/hits/internal/tally"
)

// exitError carries an exit code out of a RunE.
type exitError struct {
	code int
	err  error
}

func (e exitError) Error() string { return e.err.Error() }

func main() {
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}

func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
	root := &cobra.Command{
		Use:           "hits",
		Short:         "summarise a web server's access log",
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	var asJSON bool
	var n int
	countCmd := &cobra.Command{
		Use:   "count [file]",
		Short: "requests per status code",
		RunE: func(cmd *cobra.Command, args []string) error {
			s, err := summarise(args, stdin)
			if err != nil {
				return err
			}
			if asJSON {
				return json.NewEncoder(stdout).Encode(s.ByStatus)
			}
			tw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)
			fmt.Fprintln(tw, "status\trequests")
			for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
				fmt.Fprintf(tw, "%d\t%d\n", status, s.ByStatus[status])
			}
			return tw.Flush()
		},
	}
	countCmd.Flags().BoolVar(&asJSON, "json", false, "print JSON instead of a table")
	topCmd := &cobra.Command{
		Use:   "top [file]",
		Short: "the paths with the most requests",
		RunE: func(cmd *cobra.Command, args []string) error {
			if n < 1 {
				return exitError{2, fmt.Errorf("-n must be at least 1, got %d", n)}
			}
			s, err := summarise(args, stdin)
			if err != nil {
				return err
			}
			rows := tally.Top(s, n)
			if asJSON {
				return json.NewEncoder(stdout).Encode(rows)
			}
			tw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)
			fmt.Fprintln(tw, "path\trequests")
			for _, r := range rows {
				fmt.Fprintf(tw, "%s\t%d\n", r.Path, r.Hits)
			}
			return tw.Flush()
		},
	}
	topCmd.Flags().IntVarP(&n, "limit", "n", 3, "how many paths to show")
	topCmd.Flags().BoolVar(&asJSON, "json", false, "print JSON instead of a table")
	root.AddCommand(countCmd, topCmd)
	root.SetArgs(args)
	root.SetOut(stdout)
	root.SetErr(stderr)
	err := root.Execute()
	if err == nil {
		return 0
	}
	fmt.Fprintf(stderr, "hits: %v\n", err)
	var e exitError
	if errors.As(err, &e) {
		return e.code
	}
	return 2
}

func summarise(args []string, stdin io.Reader) (tally.Summary, error) {
	in := stdin
	switch {
	case len(args) > 1:
		return tally.Summary{}, exitError{2, fmt.Errorf("one file at most, got %d", len(args))}
	case len(args) == 1 && args[0] != "-":
		f, err := os.Open(args[0])
		if err != nil {
			return tally.Summary{}, exitError{1, err}
		}
		defer f.Close()
		in = f
	}
	s, err := tally.Count(in)
	if err != nil {
		return s, exitError{1, err}
	}
	return s, nil
}
```

Fetch Cobra at the version this course pins, build, and check that it gives the same answer:

```
ana@vm:~/cobra-cmp$ go get github.com/spf13/cobra@v1.10.2
go: downloading github.com/spf13/cobra v1.10.2
go: downloading github.com/inconshreveable/mousetrap v1.1.0
go: downloading github.com/spf13/pflag v1.0.9
go: added github.com/inconshreveable/mousetrap v1.1.0
go: added github.com/spf13/cobra v1.10.2
go: added github.com/spf13/pflag v1.0.9
ana@vm:~/cobra-cmp$ go build -o hits . && ./hits top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cobra-cmp$ ./hits tpo; echo $?
hits: unknown command "tpo" for "hits"

Did you mean this?
	top

2
ana@vm:~/cobra-cmp$ ./hits completion bash | head -1
# bash completion V2 for hits                                 -*- shell-script -*-
```

The same two paths with the same counts as section 03, and a suggestion for the typo that Cobra
prints without being asked. Cobra also adds a `completion` command by default.
**Its module brought two others with it, `pflag` and `mousetrap`**, which section 02's `go get` did
not: urfave/cli depends on nothing outside the standard library.

## Size, modules and packages

All three binaries, side by side:

```
ana@vm:~/std-hits$ go build -o hits . && stat -c "%s bytes  %n" hits ../cli-hits/hits ../cobra-cmp/hits
4031823 bytes  hits
6276176 bytes  ../cli-hits/hits
5107200 bytes  ../cobra-cmp/hits
```

The standard library version is 80 bytes away from lesson 1's **4,031,903** for the same source,
because a Go binary records the paths of the files it was compiled from, and these were compiled in
`~/std-hits` instead of `~/hits`. The other two numbers are the measurement: **the
urfave/cli version is the largest of the three, 1,168,976 bytes larger than the Cobra one**. Whatever
"lighter" means, it does not mean the binary, at least not for these versions. The measurement
does not say why; lesson 17 takes binaries apart and is where to look.

Then the modules each build depends on, which is what `go list -m all` prints:

```
ana@vm:~/std-hits$ go list -m all
example.com/hits
ana@vm:~/cli-hits$ go list -m all
example.com/hits
github.com/stretchr/testify v1.12.1
github.com/urfave/cli/v3 v3.14.0
go.yaml.in/yaml/v3 v3.0.5
ana@vm:~/cobra-cmp$ go list -m all
example.com/hits
github.com/cpuguy83/go-md2man/v2 v2.0.6
github.com/inconshreveable/mousetrap v1.1.0
github.com/russross/blackfriday/v2 v2.1.0
github.com/spf13/cobra v1.10.2
github.com/spf13/pflag v1.0.9
go.yaml.in/yaml/v3 v3.0.4
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405
```

**Not every module listed is compiled.** `go list -m all` is the module graph: every module that
some requirement names, including the ones a dependency needs only for its own tests or for
packages you never import. `testify` and `yaml` are urfave/cli's test libraries, which section
02's `tidy` downloaded; `go-md2man` and `blackfriday` serve Cobra's man-page generator. What
actually goes into the binary is a question about packages, and `go list -deps` answers it:

```
ana@vm:~/cli-hits$ go list -deps . | grep "\."
main_test.go:1:1: expected 'package', found 'EOF'
ana@vm:~/cobra-cmp$ go list -deps . | grep "\."
example.com/hits/internal/tally
vendor/golang.org/x/net/dns/dnsmessage
github.com/spf13/pflag
github.com/spf13/cobra
example.com/hits
```

The `grep` keeps the import paths with a dot in them, which leaves out the standard library's.
**One third-party package in the urfave/cli build, two in Cobra's**, and Cobra's also brings in a
package the standard library vendors, `dnsmessage`, which is part of the `net` package's resolver.
`net` arrives through `pflag`, whose flags include IP addresses and networks. `mousetrap` is in
neither list because Cobra imports it only in a file built for Windows. That is the sense in which
urfave/cli is lighter: **one module, with nothing behind it**, is one name in a vulnerability report
and one upgrade to review.

## Lines, and what they buy

```
ana@vm:~/std-hits$ wc -l main.go ../cli-hits/main.go ../cli-hits/report.go ../cobra-cmp/main.go
  144 main.go
  103 ../cli-hits/main.go
   74 ../cli-hits/report.go
  119 ../cobra-cmp/main.go
  440 total
```

The library version is the longest, **177 lines against 144**, and the count hides more than it
shows: much of lesson 1's 144 is a hand-written usage text and the dispatch `switch`, and much of
urfave/cli's 177 is struct literals declaring things lesson 1 did not have at all. The Cobra version
is shorter than both because it does less: no environment variable, no validator, so the `-n`
check is written into the command, and one long name with a one-letter shorthand, which is all a
pflag flag can have, where urfave/cli takes any number of aliases. What the lines buy
is clearer from the same call made to lesson 1's binary:

```
ana@vm:~/std-hits$ ./hits top access.log -n 2; echo $?
hits: one file at most, got 3
2
```

| | standard library (lesson 1) | urfave/cli v3.14.0 | Cobra v1.10.2 |
|---|---|---|---|
| binary | 4,031,823 bytes | 6,276,176 bytes | 5,107,200 bytes |
| modules in `go list -m all` | 1 | 4 | 8 |
| third-party packages compiled in | 0 | 1 | 2 |
| lines of command-line code | 144 | 177 | 119 |
| flags after arguments | no | yes | yes |
| help | written by hand | generated | generated |
| suggestion for a typo | none | `cli.SuggestCommand`, called by hand | built in |
| shell completion | none | one field | a command by default |
| a flag from the environment | by hand | `Sources: cli.EnvVars(…)` | by hand, or a second library |

**A flag from the environment is a field in urfave/cli and nothing in Cobra**: pflag's `Flag`
struct has no field for one. Cobra's answer is usually a companion library, Viper, which is one
more module and the subject of no lesson in this course.

## Which one, when

**The standard library** is right for a tool with one command or two, a few flags, and a reason to
stay small or dependency-free: a helper shipped inside a container image, a program in a repository
whose policy is no third-party code, anything `go-concurrency` lesson 21's flag package covers. The
cost is lesson 1's list of twenty-line features, written by you or done without.

**urfave/cli** is right for a tool with a handful of commands that wants modern flag handling,
values from the environment and generated help and completion, from **one dependency with no
dependencies of its own**. The program is a single literal you can read top to bottom, and with
`Reader`, `Writer`, `ErrWriter` and `ExitErrHandler` set it tests as lesson 1's did. Its cost is
the defaults of section 04, which have to be overridden one hook at a time, and a binary that is not
small.

**Cobra** is right for a large tree of commands, the kind Kubernetes, Hugo and the GitHub CLI have,
all three named in Cobra's own README. It brings a generator, documentation output such as man
pages, and the shape of many well-known Go tools, so its users meet something familiar. Lesson 2 covers it. What it costs is two modules compiled in, `net` among the packages, and a
second library the day a flag should come from the environment.

None of the three changes `tally`, and that is the decision of lesson 1 section 04 paying off a
second time: **the command line is a thin layer over a package that knows nothing about it**, so
replacing the layer is an afternoon, and the measurements above can be taken again when the next
version of any of the three is released.
