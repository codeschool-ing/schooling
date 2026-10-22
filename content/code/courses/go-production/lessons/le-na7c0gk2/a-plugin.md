---
title: A reporter in a shared object
version: 1
---

Somebody arriving from Python, Java or a C program with a `.dll` beside it tends to read Go's
`plugin` package as the same idea: a binary that ships today, and extensions that strangers compile
and drop in next year. **A Go plugin is much narrower than that. It is a piece of one program,
compiled on its own, that has to match the rest of the program exactly.** It is a `main` package
built with `go build -buildmode=plugin` into an ELF shared object, a `.so` file. A running program
opens it with `plugin.Open`, finds an exported variable or function by name with `Lookup`, and
calls it. That is the whole interface: two functions and one type.

This section builds two plugins for `hits` and loads them. Section 03 is the list of ways the same
two plugins refuse to load.

## Reporters

`hits` prints a table or JSON, and the formats are written into `main.go`. A reporter is a format
that lives outside it: something that takes the counts and writes them out. The work happens in
`~/plugins`, a module of its own called `example.com/hits` again, holding the `tally` package and
`tools/genlog` from lesson 1, placed there unchanged, and an `access.log` of 20,000 lines from
`genlog -n 20000`. What a reporter is goes in a package everybody imports, `report/report.go`:

```go
// Package report says what a reporter is, and keeps a list of the ones
// the program has.
package report

import (
	"io"
	"maps"
	"slices"

	"example.com/hits/internal/tally"
)

// A Reporter writes a summary out in a format of its own.
type Reporter interface {
	Report(s tally.Summary, w io.Writer) error
}

var registry = map[string]Reporter{}

// Register makes a reporter available by name. It is meant to be called
// from an init function, and it panics if the name is taken.
func Register(name string, r Reporter) {
	if _, dup := registry[name]; dup {
		panic("report: Register called twice for " + name)
	}
	registry[name] = r
}

// Get returns the reporter registered under name.
func Get(name string) (Reporter, bool) {
	r, ok := registry[name]
	return r, ok
}

// Names lists the registered reporters in alphabetical order.
func Names() []string {
	return slices.Sorted(maps.Keys(registry))
}
```

**The interface is one method, and the registry beside it is the pattern `database/sql` uses for
drivers**: a map filled by `Register`, which panics on a duplicate name exactly as `sql.Register`
does, and read by name. Nothing in this section uses it to choose a reporter. It is here for what it
shows about where a plugin's code runs, a few paragraphs down, and section 04 uses it on its own.

Two reporters, each an ordinary package that registers itself from `init`. The first writes the
status counts as CSV, `reporters/csv/csv.go`:

```go
// Package csv writes the status counts of a summary as CSV.
package csv

import (
	"encoding/csv"
	"io"
	"maps"
	"slices"
	"strconv"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
)

// Reporter is the CSV reporter.
type Reporter struct{}

func (Reporter) Report(s tally.Summary, w io.Writer) error {
	cw := csv.NewWriter(w)
	cw.Write([]string{"status", "requests"})
	for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
		cw.Write([]string{strconv.Itoa(status), strconv.Itoa(s.ByStatus[status])})
	}
	cw.Flush()
	return cw.Error()
}

func init() { report.Register("csv", Reporter{}) }
```

`reporters/mean/mean.go` prints how many requests there were and how long one took on average:

```go
// Package mean reports how long a request took on average.
package mean

import (
	"fmt"
	"io"
	"time"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
)

// Reporter is the mean-duration reporter.
type Reporter struct{}

func (Reporter) Report(s tally.Summary, w io.Writer) error {
	avg := s.Total / time.Duration(s.Lines)
	_, err := fmt.Fprintf(w, "%d requests, mean %v\n", s.Lines, avg.Round(time.Millisecond))
	return err
}

func init() { report.Register("mean", Reporter{}) }
```

Neither of them knows anything about plugins. They become plugins through a `main` package each,
and those are the shortest files in the course. `plugins/csv/main.go`:

```go
// Command csv is the CSV reporter, built as a Go plugin.
package main

import (
	"example.com/hits/report"
	"example.com/hits/reporters/csv"
)

// Reporter is a variable: Lookup returns a *report.Reporter.
var Reporter report.Reporter = csv.Reporter{}
```

`plugins/mean/main.go`:

```go
// Command mean is the mean-duration reporter, built as a Go plugin.
package main

import (
	"example.com/hits/report"
	"example.com/hits/reporters/mean"
)

// Reporter is a function: Lookup returns it as a func() report.Reporter.
func Reporter() report.Reporter { return mean.Reporter{} }
```

**What a plugin offers the host is its exported package-level names, and nothing else.** There is
no `main` function, because a plugin's `main` would never run: `go doc plugin` says that opening
one calls the `init` functions and not `main`. The two files export `Reporter` in the two forms
`Lookup` can return, a variable in `csv` and a function in `mean`. Each one is built with its own
command:

```
ana@vm:~/plugins$ go build -buildmode=plugin -o csv.so ./plugins/csv
ana@vm:~/plugins$ go build -buildmode=plugin -o mean.so ./plugins/mean
ana@vm:~/plugins$ stat -c "%s bytes  %n" csv.so mean.so
3724624 bytes  csv.so
4678072 bytes  mean.so
```

Two files of **3.7 and 4.7 MB** for reporters of about twenty lines each. A plugin carries every
package it imports, the runtime included, and `mean` imports `fmt` and `time` on top of what `csv`
needs. Section 03 explains why most of those bytes are never used once the plugin is loaded.

## The host

The program that loads them is `cmd/hits-plugin/main.go`. It counts the log the way lesson 1 does
and then hands the summary to each plugin named on its command line:

```schooling-example
{
  "language": "go",
  "file": "cmd/hits-plugin/main.go",
  "parts": [
    {
      "code": "// Command hits-plugin counts a log and hands the summary to reporters\n// loaded from Go plugins.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"plugin\"\n\n\t\"example.com/hits/internal/tally\"\n\t\"example.com/hits/report\"\n)\n",
      "note": "**`plugin` is an ordinary import from the standard library**, and importing it is what changes how this program is linked: section 03 shows the difference."
    },
    {
      "code": "func main() {\n\tif len(os.Args) < 3 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: hits-plugin <log> <plugin.so>...\")\n\t\tos.Exit(2)\n\t}\n\ts, err := count(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-plugin:\", err)\n\t\tos.Exit(1)\n\t}\n\tfor _, path := range os.Args[2:] {\n\t\tr, err := load(path)\n\t\tif err == nil {\n\t\t\terr = r.Report(s, os.Stdout)\n\t\t}\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"hits-plugin:\", err)\n\t\t\tos.Exit(1)\n\t\t}\n\t}",
      "note": "The first argument is the log and every argument after it is a plugin file. Each one is loaded and given the same summary, in the order they were named."
    },
    {
      "code": "\tfmt.Fprintln(os.Stderr, \"hits-plugin: registered\", report.Names())\n}\n",
      "note": "A diagnostic on standard error: the names in the host's registry once every plugin has been opened. Nothing in `main` registers anything, so whatever appears here was put there by a plugin."
    },
    {
      "code": "func count(name string) (tally.Summary, error) {\n\tf, err := os.Open(name)\n\tif err != nil {\n\t\treturn tally.Summary{}, err\n\t}\n\tdefer f.Close()\n\treturn tally.Count(f)\n}\n",
      "note": "The counting is lesson 1's, unchanged."
    },
    {
      "code": "func load(path string) (report.Reporter, error) {\n\tp, err := plugin.Open(path)\n\tif err != nil {\n\t\treturn nil, err\n\t}",
      "note": "**`plugin.Open` maps the file into the process and runs the `init` functions of every package the program did not already have.** That is where `csv` and `mean` register themselves. A path opened a second time returns the same `*Plugin` without running anything."
    },
    {
      "code": "\tsym, err := p.Lookup(\"Reporter\")\n\tif err != nil {\n\t\treturn nil, err\n\t}",
      "note": "`Lookup` finds an exported name and returns it as a `plugin.Symbol`, which is `any`. The name is a string, so a typo is found when the program runs, never when it compiles."
    },
    {
      "code": "\tswitch v := sym.(type) {\n\tcase *report.Reporter:\n\t\treturn *v, nil\n\tcase func() report.Reporter:\n\t\treturn v(), nil\n\t}\n\treturn nil, fmt.Errorf(\"%s: Reporter is a %T\", path, sym)\n}",
      "note": "**A variable comes back as a pointer to the variable, and a function comes back as the function.** So `plugins/csv` arrives as a `*report.Reporter` and `plugins/mean` as a `func() report.Reporter`. Asserting `sym.(report.Reporter)` on the first fails, because a pointer to an interface has no methods."
    }
  ]
}
```

Built and run with both plugins:

```
ana@vm:~/plugins$ go build -o hits-plugin ./cmd/hits-plugin
ana@vm:~/plugins$ ./hits-plugin access.log csv.so mean.so
status,requests
200,7554
201,1256
204,1248
301,1192
304,1229
400,1223
401,1226
404,2549
500,1269
503,1254
20000 requests, mean 200ms
hits-plugin: registered [csv mean]
```

The CSV is the status table of lesson 1, and the mean is 200 ms over 20,000 requests. The last line
is the one to read twice. **`registered [csv mean]` comes from the host's own registry, and nothing
in the host ever called `Register`.** The `init` functions inside the two `.so` files ran when
`plugin.Open` loaded them, and they wrote into the map that `cmd/hits-plugin` imported. The plugin
did not get a registry of its own.

The same file named twice shows the other rule `plugin.Open` follows:

```
ana@vm:~/plugins$ ./hits-plugin access.log csv.so csv.so | wc -l
hits-plugin: registered [csv]
22
```

Twenty-two lines are the eleven CSV lines twice, so the reporter ran twice. Its `init` ran once:
a second `Register("csv", …)` would have panicked with `Register called twice for csv`. **A path
that has already been opened returns the plugin already in memory**, initialised once and kept for
the life of the process.

Importing `plugin` also changes what kind of file the host is:

```
ana@vm:~/plugins$ stat -c "%s bytes  %n" hits-plugin
4897008 bytes  hits-plugin
ana@vm:~/plugins$ readelf -d hits-plugin | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
```

`hits-plugin` holds no reporter at all, and at 4,897,008 bytes it is already bigger than lesson
1's whole `hits`, which was 4,031,903. **And it needs `libc.so.6`**, because loading a shared
object at run time is the C library's `dlopen`, reached through cgo. A host that loads plugins is a
dynamically linked program, whatever it loads and whether it loads anything at all.
