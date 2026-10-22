---
title: A tree of commands
version: 1
---

Lesson 1 ended with a list of features the hand-written `hits` lacked: a suggestion for a typo,
help for each subcommand, completion with the Tab key. **Cobra is a library that supplies all of
them. The price is that you describe your program as a tree of values instead of writing the
dispatch yourself.** Each node of the tree is a `cobra.Command`, a struct with a name, some help text,
its flags and a function to run. Cobra reads the words on the command line, walks down the tree as
far as they match, parses the flags of the node it reached and calls that node's function.

It is often described as a framework you start with a generator, and the generator does exist:
`cobra-cli`, a separate module (v1.3.0 on the module proxy when this was written), which writes a
`cmd/` directory with one file per command. Each of those files declares its command as a
package-level variable and attaches it to its parent in an `init` function. **This lesson uses the
library alone and builds the tree inside functions.** The reason matters to section 04's test: a
command held in a package-level variable keeps the flag values of its last run, so a test that runs
it twice sees the first run's `-n` in the second. The generator was not used here, and you do not
need it to follow the lesson.

## The same project, a new front

The program lives in a new module, `~/cobra-hits`, so that lesson 1's `~/hits` stays as it is and
the two can be compared. Make it the way lesson 1 made `~/hits`, with `go mod init example.com/hits`.
Then copy two files across unchanged, **the `tally` package from lesson 1** (`internal/tally/tally.go`)
and its log generator (`tools/genlog/main.go`), and write the same `access.log` with
`go run ./tools/genlog -n 20000 > access.log`. The module path is the same as lesson 1's, so the
import of `tally` does not change by a character.

Cobra is the first module this course downloads. `go get` names a version, which the go command
records in `go.mod`:

```
ana@vm:~/cobra-hits$ go get github.com/spf13/cobra@v1.10.2
go: added github.com/inconshreveable/mousetrap v1.1.0
go: added github.com/spf13/cobra v1.10.2
go: added github.com/spf13/pflag v1.0.9
```

On a machine that has never fetched them, each `added` line is preceded by a `go: downloading` line;
Ana's module cache already held these three. One request brought **three modules**: Cobra itself,
`pflag`, the flag parser it is built on, and `mousetrap`, which Cobra uses only on Windows.

## The command line, as a tree

`main.go` replaces lesson 1's whole file. It keeps the shape that made lesson 1 testable, a `main`
that only calls `run`, and moves everything else into three constructors, one per command. **It stays one file**, because three
commands in 163 lines read more easily together than spread over a `cmd/` package; that layout earns
its place when there are a dozen commands, each with helpers of its own. Save it as `main.go`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"github.com/spf13/cobra\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Lesson 1's imports, with `flag` gone and one line added. **Cobra brings its own flag parser, `pflag`**, so nothing here imports a flag package at all."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "`main` is lesson 1's, word for word: the process's arguments and streams go to `run`, and what `run` returns is the exit code."
    },
    {
      "code": "// run builds the command tree, executes it on args and turns the result\n// into an exit code: 0, 1 for a run that failed, 2 for a mistake in the\n// command line.\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\troot := newRootCmd()\n\troot.SetArgs(args)\n\troot.SetIn(stdin)\n\troot.SetOut(stdout)\n\troot.SetErr(stderr)\n\tcmd, err := root.ExecuteC()\n\tif err == nil {\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\tvar failed runError\n\tif errors.As(err, &failed) {\n\t\treturn 1\n\t}\n\tfmt.Fprintf(stderr, \"Run '%s --help' for usage.\\n\", cmd.CommandPath())\n\treturn 2\n}\n",
      "note": "**`run` keeps lesson 1's signature and changes its body.** It builds a fresh command tree, hands it the arguments and the three streams, and lets Cobra find the subcommand. `ExecuteC` returns the command it ended up in as well as the error, which is how the hint can name `hits top`. Section 04 is about the three exits."
    },
    {
      "code": "// runError marks an error from a command that was called correctly and then\n// failed. Every other error Cobra hands back is a mistake in the command line.\ntype runError struct{ err error }\n\nfunc (e runError) Error() string { return e.err.Error() }\nfunc (e runError) Unwrap() error { return e.err }\n",
      "note": "A wrapper with no behaviour of its own. Its only job is to let `run` tell a failed run from a mistyped command, and section 04 says why Cobra cannot do that for you."
    },
    {
      "code": "func newRootCmd() *cobra.Command {\n\tvar asJSON bool\n\troot := &cobra.Command{\n\t\tUse:   \"hits\",\n\t\tShort: \"Summarise a web server's access log\",\n\t\tLong: \"hits reads an access log, one request per line, and counts it.\\n\" +\n\t\t\t\"With no file, or with -, it reads standard input.\",\n\t\tSilenceUsage:  true,\n\t\tSilenceErrors: true,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\treturn errors.New(\"which command? count or top\")\n\t\t},\n\t}\n\troot.PersistentFlags().BoolVar(&asJSON, \"json\", false, \"print JSON instead of a table\")\n\troot.AddCommand(newCountCmd(&asJSON), newTopCmd(&asJSON))\n\treturn root\n}\n",
      "note": "**The root command is `hits` itself.** `Use`, `Short` and `Long` are the text the generated help prints. The two `Silence` fields and the root's own `RunE` are there for the exit codes of section 04. `--json` is declared once, on the root, as a persistent flag that both subcommands inherit; section 03 is about that difference."
    },
    {
      "code": "func newCountCmd(asJSON *bool) *cobra.Command {\n\treturn &cobra.Command{\n\t\tUse:               \"count [file]\",\n\t\tShort:             \"Requests per status code\",\n\t\tArgs:              cobra.MaximumNArgs(1),\n\t\tValidArgsFunction: logFiles,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\ts, err := summarise(cmd, args)\n\t\t\tif err != nil {\n\t\t\t\treturn err\n\t\t\t}\n\t\t\tif *asJSON {\n\t\t\t\treturn encode(cmd.OutOrStdout(), s.ByStatus)\n\t\t\t}\n\t\t\ttw := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)\n\t\t\tfmt.Fprintln(tw, \"status\\trequests\")\n\t\t\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\t\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t\t\t}\n\t\t\treturn flush(tw)\n\t\t},\n\t}\n}\n",
      "note": "A subcommand is a `cobra.Command` added to the root. `Args: cobra.MaximumNArgs(1)` replaces lesson 1's hand-written \"one file at most\" check. **`RunE` returns an error instead of an exit code**, and the table goes to `cmd.OutOrStdout()`, which is whatever writer `run` gave the tree."
    },
    {
      "code": "func newTopCmd(asJSON *bool) *cobra.Command {\n\tvar n int\n\tcmd := &cobra.Command{\n\t\tUse:               \"top [file]\",\n\t\tShort:             \"The paths with the most requests\",\n\t\tArgs:              cobra.MaximumNArgs(1),\n\t\tValidArgsFunction: logFiles,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\ts, err := summarise(cmd, args)\n\t\t\tif err != nil {\n\t\t\t\treturn err\n\t\t\t}\n\t\t\trows := tally.Top(s, n)\n\t\t\tif *asJSON {\n\t\t\t\treturn encode(cmd.OutOrStdout(), rows)\n\t\t\t}\n\t\t\ttw := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)\n\t\t\tfmt.Fprintln(tw, \"path\\trequests\")\n\t\t\tfor _, r := range rows {\n\t\t\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t\t\t}\n\t\t\treturn flush(tw)\n\t\t},\n\t}\n\tcmd.Flags().IntVarP(&n, \"number\", \"n\", 3, \"how many paths to show\")\n\treturn cmd\n}\n",
      "note": "`top` adds one local flag, `-n`, now also spelt `--number`. The variable it fills is declared inside the constructor, so **every tree `run` builds starts from the default of 3**."
    },
    {
      "code": "// logFiles is what Tab offers for the file argument: files ending in .log,\n// and nothing once a file has been named.\nfunc logFiles(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {\n\tif len(args) > 0 {\n\t\treturn nil, cobra.ShellCompDirectiveNoFileComp\n\t}\n\treturn []string{\"log\"}, cobra.ShellCompDirectiveFilterFileExt\n}\n",
      "note": "Not used by anything a person types: this answers the shell when somebody presses Tab. Section 05 shows the question and the answer."
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(cmd *cobra.Command, args []string) (tally.Summary, error) {\n\tin := cmd.InOrStdin()\n\tif len(args) == 1 && args[0] != \"-\" {\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\treturn tally.Summary{}, runError{err}\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\treturn s, runError{err}\n\t}\n\treturn s, nil\n}\n",
      "note": "Lesson 1's `summarise` without its argument count, which Cobra now checks before `RunE` is called. **A file that will not open and a line that will not parse come back wrapped in `runError`**: the command line was right and the run failed."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write that fails\n// is a failed run.\nfunc flush(tw *tabwriter.Writer) error {\n\tif err := tw.Flush(); err != nil {\n\t\treturn runError{err}\n\t}\n\treturn nil\n}\n\nfunc encode(w io.Writer, v any) error {\n\tif err := json.NewEncoder(w).Encode(v); err != nil {\n\t\treturn runError{err}\n\t}\n\treturn nil\n}",
      "note": "The same two writers as lesson 1, returning errors instead of printing them. `run` prints every error in one place."
    }
  ]
}
```


`go get` listed Cobra as indirect, because no code imported it yet. `go mod tidy` reads the imports
and puts that right, and then the tool builds:

```
ana@vm:~/cobra-hits$ go mod tidy
ana@vm:~/cobra-hits$ cat go.mod
module example.com/hits

go 1.27.1

require github.com/spf13/cobra v1.10.2

require (
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/pflag v1.0.9 // indirect
)
ana@vm:~/cobra-hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./tools/genlog/main.go
ana@vm:~/cobra-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
5108043 bytes  hits
ana@vm:~/cobra-hits$ ./hits count access.log
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
ana@vm:~/cobra-hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
```

**Both tables are lesson 1's, digit for digit**, which is the check that matters after replacing a
command line: the counting did not move, so the answers did not either. `go.mod` now says `require`
for Cobra and `// indirect` for the two modules it brought, since nothing in `hits` imports them by
name.

The streams survived the move as well. `SetIn`, `SetOut` and `SetErr` give the tree the readers and
writers `run` was handed, and inside a command `cmd.InOrStdin()` and `cmd.OutOrStdout()` give them
back. A command that wrote to `os.Stdout` directly would work from the terminal and print nothing
into a test's buffer, which is the same trap lesson 1 avoided by passing writers to `run`.

## What it cost

A library is code you did not write and still ship. Three questions measure it: how many modules
your build now depends on, how many of them end up in the binary, and how much bigger the binary is.

```
ana@vm:~/cobra-hits$ go list -m all
example.com/hits
github.com/cpuguy83/go-md2man/v2 v2.0.6
github.com/inconshreveable/mousetrap v1.1.0
github.com/russross/blackfriday/v2 v2.1.0
github.com/spf13/cobra v1.10.2
github.com/spf13/pflag v1.0.9
go.yaml.in/yaml/v3 v3.0.4
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405
ana@vm:~/cobra-hits$ go version -m hits | grep dep
	dep	github.com/spf13/cobra	v1.10.2	h1:DMTTonx5m65Ic0GOoRY2c16WCbHxOOw6xxezuLaBpcU=
	dep	github.com/spf13/pflag	v1.0.9	h1:9exaQaMOCwffKiiiYk6/BndUBv+iRViNW+4lEMi0PvY=
ana@vm:~/cobra-hits$ go list -deps . | grep template
text/template/parse
text/template
```

**`go list -m all` prints the module graph, and it is larger than what gets compiled.** Lesson 1's
`hits` had one line here, its own module; this one has eight. Three are the modules `go get` added.
The other four arrive through Cobra's `go.mod` and the files it leads to. `go-md2man`, and the
`blackfriday` it requires, serve the man-page generator in Cobra's `doc` package; `yaml` serves the same package's
YAML output, and `check.v1` is what `yaml` tests itself with. The go command needs their versions to
resolve the graph although `hits` imports none of them. `go version -m` reads the list the linker
wrote into the binary, and **only two modules were compiled in**: Cobra and `pflag`. The standard
library grew too: Cobra renders its help through `text/template`, a package lesson 1's program did
not use.

| | lesson 1, standard library | this lesson, Cobra |
|---|---|---|
| modules in the graph (`go list -m all`) | 1 | 8 |
| modules compiled in (`go version -m`) | 0 besides `hits` | 2 |
| binary | 4,031,903 bytes | 5,108,043 bytes |
| `main.go` | 144 lines | 163 lines |

The binary is **1,076,140 bytes larger**, about 27%, for a program whose own code barely changed;
lesson 17 is about making binaries smaller with compiler and linker flags. The last row is the
surprise: `main.go` did not shrink. What moved into the library is not lines of
`hits` but features `hits` never had:

```
ana@vm:~/cobra-hits$ wc -l main.go
163 main.go
ana@vm:~/cobra-hits$ cd $(go env GOMODCACHE)/github.com/spf13 && cat $(ls cobra@v1.10.2/*.go pflag@v1.0.9/*.go | grep -v _test) | wc -l
12370
```

**12,370 lines of Cobra and `pflag`**, tests left out, now stand behind those 163. Lesson 1's
hand-written usage text, its `switch` over the first word and its `flagError` are gone; in their
place are three constructors and the code sections 04 and 05 explain. Whether that trade is worth a
megabyte is the question lesson 3 asks again, of urfave/cli.
