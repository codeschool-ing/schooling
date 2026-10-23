---
title: One tool, several commands
version: 1
---

`go build`, `go test` and `go vet` are one program. So are `git commit` and `git log`. **A tool with
subcommands is a single binary whose first argument chooses what it does**, and each choice takes
flags of its own: `go test -run` means nothing to `go build`. `hits` is built that way, with two
subcommands, `count` and `top`, and nothing outside the standard library.

It comes in two parts, and the split is the first decision worth copying. The counting has nothing
to do with a command line, so it lives in a package of its own, `internal/tally`. The `internal`
directory makes it importable from inside this module and from nowhere else, which leaves you free
to change it. Lessons 2 to 4 put three different command lines in front of this same package, and
lessons 12 and 13 make it faster. Save it as `internal/tally/tally.go`:

```go
// Package tally reads the lines of an access log and counts them.
package tally

import (
	"bufio"
	"cmp"
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
	"time"
)

// Entry is one line of the log.
type Entry struct {
	Time     time.Time
	Method   string
	Path     string
	Status   int
	Duration time.Duration
}

// Parse reads one line: a time, a method, a path, a status and a duration,
// separated by spaces.
func Parse(line string) (Entry, error) {
	f := strings.Fields(line)
	if len(f) != 5 {
		return Entry{}, fmt.Errorf("want 5 fields, got %d", len(f))
	}
	t, err := time.Parse(time.RFC3339, f[0])
	if err != nil {
		return Entry{}, err
	}
	status, err := strconv.Atoi(f[3])
	if err != nil {
		return Entry{}, fmt.Errorf("status: %w", err)
	}
	d, err := time.ParseDuration(f[4])
	if err != nil {
		return Entry{}, err
	}
	return Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil
}

// Summary is what Count found.
type Summary struct {
	Lines    int
	ByStatus map[int]int
	ByPath   map[string]int
	Total    time.Duration
}

// Count reads every line from r. A line it cannot parse stops it, and the
// error names the line.
func Count(r io.Reader) (Summary, error) {
	s := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}
	sc := bufio.NewScanner(r)
	for n := 1; sc.Scan(); n++ {
		e, err := Parse(sc.Text())
		if err != nil {
			return s, fmt.Errorf("line %d: %w", n, err)
		}
		s.Lines++
		s.ByStatus[e.Status]++
		s.ByPath[e.Path]++
		s.Total += e.Duration
	}
	return s, sc.Err()
}

// PathCount is one row of Top.
type PathCount struct {
	Path string `json:"path"`
	Hits int    `json:"hits"`
}

// Top returns the n paths with the most requests, the most first. Paths
// with the same count come in alphabetical order.
func Top(s Summary, n int) []PathCount {
	rows := make([]PathCount, 0, len(s.ByPath))
	for p, h := range s.ByPath {
		rows = append(rows, PathCount{p, h})
	}
	slices.SortFunc(rows, func(a, b PathCount) int {
		return cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))
	})
	return rows[:min(n, len(rows))]
}
```

`Parse` turns one line into an `Entry` and says precisely what is wrong with a line it cannot read.
`Count` reads lines until the input ends and keeps three tallies. `Top` sorts the paths by count and
breaks ties alphabetically, so two runs over the same log always print the same table. **None of it
prints anything or exits**: it returns values and errors, and deciding what a person sees is the
command line's job.

## The command line

The second part is `main.go`, at the top of the module, and it is all about the person typing.
Read it in pieces:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "The package doc comment names the command, which is the convention for a `main` package. `tally` is imported by its full path inside this module."
    },
    {
      "code": "const usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n\nWith no file, or with -, hits reads standard input.\n`\n",
      "note": "The text printed when somebody asks for help or gets the command wrong. **Written by hand**, because nothing in the standard library knows that this program has subcommands."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "**`main` does one thing: it passes the process's arguments and streams to `run` and exits with what `run` returns.** Everything that can be tested lives in `run`, which section 05 tests without starting a process."
    },
    {
      "code": "func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n",
      "note": "The first word picks the subcommand and the rest is handed to it. An empty command line and an unknown word are both mistakes by the caller, so both print the usage to standard error and return 2."
    },
    {
      "code": "func count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}",
      "note": "**Each subcommand owns a `flag.FlagSet`**, with flags no other subcommand sees. `ContinueOnError` makes `Parse` return the error instead of exiting, so the subcommand chooses the exit code; `SetOutput` sends the flag package's messages to the same stream as every other complaint."
    },
    {
      "code": "\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n",
      "note": "What is left after the flags is the file to read. The table goes through a `tabwriter`, which pads each column to its widest cell; status codes come out sorted because a map has no order of its own."
    },
    {
      "code": "func top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n",
      "note": "The second subcommand has one flag more than the first, `-n`, and the same shape otherwise."
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n",
      "note": "**No file, or a file called `-`, means standard input.** Two files is a usage mistake and gets 2; a file that will not open, or a line that will not parse, is a failure of the run and gets 1."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n",
      "note": "**A write can fail**, on a full disk or a closed file, and both ways of writing report it instead of dropping it. A table is held by the `tabwriter` until `Flush`, so that is where its error appears."
    },
    {
      "code": "// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}",
      "note": "`-h` comes back from `Parse` as `flag.ErrHelp`. Asking for help is not an error, so it is 0; anything else the package refused is 2."
    }
  ]
}
```


Built, and asked both questions about the 20,000 lines:

```
ana@vm:~/hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./tools/genlog/main.go
ana@vm:~/hits$ go build -o hits . && stat -c "%s bytes  %n" hits
4031903 bytes  hits
ana@vm:~/hits$ ./hits count access.log
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
ana@vm:~/hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
ana@vm:~/hits$ ./hits top -json access.log
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542},{"path":"/static/app.js","hits":2526}]
```

`200` is a little over a third of the log, which is what six `200`s in `genlog`'s list of sixteen
predict, and `404` is about twice any other error because it is listed twice. The JSON came out with
the default of three paths and the field names from the struct tags in `tally`. A binary of
**4,031,903 bytes** for a program this small is the runtime and the parts of the standard library it
uses; lesson 17 takes it apart.

## Mistakes, and who made them

The hand-written dispatch has to handle what the flag package handled for free in section 03. Here is
the program called with nothing, with a typo, with a request for help and with a bad value:

```
ana@vm:~/hits$ ./hits; echo $?
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
2
ana@vm:~/hits$ ./hits cont access.log; echo $?
hits: unknown command "cont"

usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
2
ana@vm:~/hits$ ./hits top -h; echo $?
Usage of top:
  -json
    	print JSON instead of a table
  -n int
    	how many paths to show (default 3)
0
ana@vm:~/hits$ ./hits top -n five access.log; echo $?
invalid value "five" for flag -n: parse error
Usage of top:
  -json
    	print JSON instead of a table
  -n int
    	how many paths to show (default 3)
2
```

**Every one of these is the caller's mistake, and every one ends in 2**, except the request for help,
which is not a mistake. The `-h` listing belongs to `top` alone and knows nothing of `count`, because
each `FlagSet` describes only its own flags.

What it does not do is just as visible. `cont` is one letter from `count` and the program does not
say so. `hits help top` prints the general usage, not `top`'s. There is no way to complete a
subcommand's name with the Tab key. Each of those is twenty lines you could write by hand.
**That pile of twenty-line features is exactly what lesson 2's Cobra is**: the same program, with the
dispatch, the help, the suggestions and the completion written once by somebody else.
