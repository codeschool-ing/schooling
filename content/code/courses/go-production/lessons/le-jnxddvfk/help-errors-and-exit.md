---
title: Help, errors and the exit code
version: 1
---

A library that writes your help and parses your flags also decides what happens when the parse
fails, and **its defaults are not lesson 1's contract**. Lesson 1 section 05 fixed three promises:
results on standard output, complaints on standard error, and an exit status of 0, 1 or 2 that a
script can act on. Section 02's `main.go` uses the shape urfave/cli's own documentation shows, and
it breaks all three on the first mistyped flag. This section shows where, then rewrites `main.go`
with three hooks the library offers and a `run` function like lesson 1's, and tests it.

## What the defaults do

A value that is not a number, first with both streams on the screen and then with standard error
thrown away:

```
ana@vm:~/cli-hits$ ./hits top -n five access.log; echo $?
Incorrect Usage: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax

NAME:
   hits top - the paths with the most requests

USAGE:
   hits top [file]

OPTIONS:
   -n int, --limit int  how many paths to show (default: 3) [$HITS_TOP]
   --json               print JSON instead of a table
   --help, -h           show help
hits: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax
1
ana@vm:~/cli-hits$ ./hits top -n five access.log 2>/dev/null | head -3
NAME:
   hits top - the paths with the most requests
```

Three things are wrong at once. **The complaint is printed twice**, once by the library as
`Incorrect Usage` and once by `main`, which printed the error `Run` returned. The exit status is 1,
which in lesson 1's table means "called correctly, and the run failed", for a call that was plainly
wrong. And the second command shows where the help went: **with standard error discarded, the
listing still arrived, so it was written to standard output**. In a pipeline, the next program would
read `NAME:` and `hits top - the paths with the most requests` as data.

Then a typo in the command, no command at all, and two files:

```
ana@vm:~/cli-hits$ ./hits cont access.log; echo $?
No help topic for 'cont'
3
ana@vm:~/cli-hits$ ./hits >/dev/null; echo $?
0
ana@vm:~/cli-hits$ ./hits top a.log b.log; echo $?
hits: one file at most, got 2
2
```

`cont` ended in **status 3**, a code lesson 1 never used, with a message about help topics. With no
command the library printed the root's help and called it success. Two files came out right, 2 and
one line, and the reason is worth knowing. That error was made by `cli.Exit` in `summarise`, and
**by default the library handles an `ExitCoder` itself, printing its message and calling
`os.Exit` from inside `Run`**. `main`'s own `os.Exit(1)` never ran. The typo went the same way: the
library made a `cli.Exit(…, 3)` of its own and exited.

That last behaviour is the one that matters beyond appearance. A function that may end the process
from inside it cannot be called from a test, because the test binary is the process.

## Three hooks and a `run`

Each default has a field that replaces it. Rewrite `main.go` in `~/cli-hits`; `report.go` stays as it
is:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\n\t\"github.com/urfave/cli/v3\"\n)\n",
      "note": "The same imports as section 02's version, plus `errors` and `io` for the testable entry point."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "**`main` is back to lesson 1's one line.** The process's arguments and streams go to `run`, and its answer is the exit status."
    },
    {
      "code": "// run builds the command, runs it on args and turns what comes back into\n// lesson 1's exit codes: 0 it worked, 1 the run failed, 2 the call was wrong.\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\terr := newApp(stdin, stdout, stderr).Run(context.Background(), append([]string{\"hits\"}, args...))\n\tif err == nil {\n\t\treturn 0\n\t}\n\tvar exit cli.ExitCoder\n\tif errors.As(err, &exit) {\n\t\tif msg := err.Error(); msg != \"\" {\n\t\t\tfmt.Fprintln(stderr, msg)\n\t\t}\n\t\treturn exit.ExitCode()\n\t}\n\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\treturn 1\n}\n",
      "note": "`run` puts the program name back in front, because `Run` expects `os.Args` whole. **Every error that carries a code was made by `cli.Exit`**, here or in `report.go`, so it is printed and its code returned. Anything else is a failure nobody classified, and gets 1."
    },
    {
      "code": "func newApp(stdin io.Reader, stdout, stderr io.Writer) *cli.Command {\n\treturn &cli.Command{\n\t\tName:                  \"hits\",\n\t\tUsage:                 \"summarise a web server's access log\",\n\t\tReader:                stdin,\n\t\tWriter:                stdout,\n\t\tErrWriter:             stderr,\n\t\tExitErrHandler:        func(context.Context, *cli.Command, error) {},\n\t\tOnUsageError:          usageError,\n\t\tEnableShellCompletion: true,\n\t\tAction:                noCommand,",
      "note": "**`Reader`, `Writer` and `ErrWriter` are the three streams**, and the subcommands inherit them, which is why `report.go` could write to `cmd.Writer` from the start. `ExitErrHandler` is the line that matters most: an empty function means the library never calls `os.Exit` itself, and the decision comes back to `run`."
    },
    {
      "code": "\t\tCommands: []*cli.Command{\n\t\t\t{\n\t\t\t\tName:         \"count\",\n\t\t\t\tUsage:        \"requests per status code\",\n\t\t\t\tArgsUsage:    \"[file]\",\n\t\t\t\tFlags:        []cli.Flag{jsonFlag()},\n\t\t\t\tOnUsageError: usageError,\n\t\t\t\tAction:       count,\n\t\t\t},\n\t\t\t{\n\t\t\t\tName:      \"top\",\n\t\t\t\tUsage:     \"the paths with the most requests\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags: []cli.Flag{\n\t\t\t\t\t&cli.IntFlag{\n\t\t\t\t\t\tName:      \"n\",\n\t\t\t\t\t\tAliases:   []string{\"limit\"},\n\t\t\t\t\t\tValue:     3,\n\t\t\t\t\t\tUsage:     \"how many paths to show\",\n\t\t\t\t\t\tSources:   cli.EnvVars(\"HITS_TOP\"),\n\t\t\t\t\t\tValidator: atLeastOne,\n\t\t\t\t\t},\n\t\t\t\t\tjsonFlag(),\n\t\t\t\t},\n\t\t\t\tOnUsageError: usageError,\n\t\t\t\tAction:       top,\n\t\t\t},\n\t\t},\n\t}\n}\n",
      "note": "The two commands are section 02's, each with `OnUsageError` added. **The hook is not inherited**: a command without it falls back to the library's answer, help on standard output and all."
    },
    {
      "code": "// usageError replaces the library's answer to a bad flag, which prints the\n// whole help to standard output, with one line on standard error and 2.\nfunc usageError(ctx context.Context, cmd *cli.Command, err error, _ bool) error {\n\treturn cli.Exit(fmt.Sprintf(\"%s: %v (see '%s --help')\", cmd.FullName(), err, cmd.FullName()), 2)\n}\n",
      "note": "Called with the command whose flags failed, so `cmd.FullName()` says `hits top` rather than `hits`. Wrapping the message in `cli.Exit(…, 2)` is what tells `run` which code to use."
    },
    {
      "code": "// noCommand runs when no subcommand matched: either none was given, or the\n// first word is not one of them.\nfunc noCommand(ctx context.Context, cmd *cli.Command) error {\n\tif !cmd.Args().Present() {\n\t\treturn cli.Exit(\"hits: no command given (see 'hits --help')\", 2)\n\t}\n\tname := cmd.Args().First()\n\treturn cli.Exit(fmt.Sprintf(\"hits: unknown command %q, did you mean %q?\", name, cli.SuggestCommand(cmd.Commands, name)), 2)\n}\n",
      "note": "**The root's `Action` is the fallback for a first word that names no command.** Left out, the library would answer `No help topic` with status 3. `cli.SuggestCommand` is the library's own nearest-name search, exported."
    },
    {
      "code": "func jsonFlag() cli.Flag {\n\treturn &cli.BoolFlag{Name: \"json\", Usage: \"print JSON instead of a table\"}\n}\n\nfunc atLeastOne(n int) error {\n\tif n < 1 {\n\t\treturn fmt.Errorf(\"must be at least 1, got %d\", n)\n\t}\n\treturn nil\n}",
      "note": "Unchanged from section 02."
    }
  ]
}
```

**`ExitErrHandler` set to a function that does nothing is the change everything else rests on.**
The library still builds every `cli.Exit`, but now hands it back from `Run` instead of acting on it,
and `run` prints the message and returns the code. Where each kind of failure enters is drawn below;
the three boxes on the right are the three places this program decides an exit code.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Where each failure of hits goes in the second version. Inside cmd.Run, three stages run in order: parse the flags, find the command, run the Action. A bad flag or value is caught by OnUsageError, which returns cli.Exit with 2. No command, or an unknown one, reaches the root&#x27;s Action, which returns cli.Exit with 2. A file that will not open or a line that will not parse comes back from summarise as cli.Exit with 1, and two files as cli.Exit with 2. Every error then passes the ExitErrHandler, which does nothing, so Run returns it, and run prints the message and returns its code as the exit status.\"><defs><marker id=\"ue-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ue-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inside cmd.Run, in order</text><rect x=\"40\" y=\"52\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">parse the flags</text><line x1=\"120\" y1=\"88\" x2=\"120\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"40\" y=\"117\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">find the command</text><line x1=\"120\" y1=\"153\" x2=\"120\" y2=\"181\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"40\" y=\"182\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run the Action</text><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a bad flag or value</text><text x=\"345\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no command, or an unknown one</text><text x=\"345\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a file that will not open,</text><text x=\"345\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a bad line, or two files</text><line x1=\"200\" y1=\"70\" x2=\"238\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"70\" x2=\"488\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"200\" y1=\"135\" x2=\"238\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"135\" x2=\"488\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"200\" y1=\"200\" x2=\"238\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"200\" x2=\"488\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><rect x=\"490\" y=\"48\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">OnUsageError</text><text x=\"595\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 2)</text><rect x=\"490\" y=\"113\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the root&#x27;s Action</text><text x=\"595\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 2)</text><rect x=\"490\" y=\"178\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">summarise</text><text x=\"595\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 1 or 2)</text><line x1=\"595\" y1=\"222\" x2=\"595\" y2=\"262\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"400\" y=\"264\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ExitErrHandler</text><text x=\"550\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">does nothing, so Run returns the error</text><line x1=\"400\" y1=\"289\" x2=\"318\" y2=\"289\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"20\" y=\"264\" width=\"296\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run(args, stdin, stdout, stderr) int</text><text x=\"168\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prints the message, returns its code</text></svg>", "caption": "Where each failure enters with the second main.go, and what answers for it. All three answers end in cli.Exit, and run reads the code back out."}
```

The same calls on the rebuilt binary, and one more that fails for a reason of its own:

```
ana@vm:~/cli-hits$ go build -o hits .
ana@vm:~/cli-hits$ ./hits top -n five access.log; echo $?
hits top: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax (see 'hits top --help')
2
ana@vm:~/cli-hits$ ./hits top -n five access.log 2>/dev/null | wc -c
0
ana@vm:~/cli-hits$ ./hits cont access.log; echo $?
hits: unknown command "cont", did you mean "count"?
2
ana@vm:~/cli-hits$ ./hits; echo $?
hits: no command given (see 'hits --help')
2
ana@vm:~/cli-hits$ ./hits top a.log b.log; echo $?
hits: one file at most, got 2
2
ana@vm:~/cli-hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
```

**Every message is now one line on standard error**: `wc -c` counted zero bytes on standard output
for the bad value, where section 02's version had written a whole help screen there. The codes are
lesson 1's, 2 for each mistake in the call and 1 for the file that would not open, and the typo got
a suggestion from `cli.SuggestCommand`. Help that is asked for with `--help` still goes to standard
output, as it should: then the help is the result.

## Where the defaults still show through

Two calls get past all three hooks:

```
ana@vm:~/cli-hits$ ./hits help nope; echo $?
No help topic for 'nope'
3
ana@vm:~/cli-hits$ HITS_TOP=x ./hits top access.log; echo $?
hits: could not parse "x" as int value from environment variable "HITS_TOP" for flag n: strconv.ParseInt: parsing "x": invalid syntax
1
```

**The built-in `help` command has its own not-found path**, and it returns the library's
`cli.Exit(…, 3)` without consulting the root's `Action`; `run` faithfully passes the 3 on. A value
from the environment that does not parse is checked after the flags are read, outside the path
`OnUsageError` covers, and arrives at `run` as a plain error, so it gets the 1 reserved for errors
nobody classified. Both are mistakes by the caller, and both would need more code to report as 2:
`help` could be hidden with `HideHelpCommand` and replaced, and `run` could look at the error's
text. Neither is done here, and that is a fair picture of a framework: **its defaults keep reaching
the user through paths you did not write**. A contract is held by testing it rather than by
assuming the library shares it.

The `Suggest` field you may see in the library's documentation adds a "Did you mean" line to its own
usage-error message, the one `OnUsageError` replaces here, which is why `hits` computes its
suggestion itself.

## Completion comes free

`EnableShellCompletion: true` added a hidden command, `completion`, that prints a script for bash,
zsh, fish or PowerShell, and a hidden flag the script uses to ask the program what may come next:

```
ana@vm:~/cli-hits$ ./hits completion bash | head -1
# This is a shell completion script auto-generated by https://github.com/urfave/cli for bash.
ana@vm:~/cli-hits$ ./hits --generate-shell-completion
count:requests per status code
top:the paths with the most requests
help:Shows a list of commands or help for one command
```

**The script calls `hits` itself every time Tab is pressed**, with `--generate-shell-completion` on
the end of what has been typed so far, and offers what comes back. `hits completion --help` says how
to load it: `source <(hits completion bash)` in `~/.bashrc`. The script registers itself for the
command name `hits`, so the binary has to be on your `PATH`, in `~/go/bin` after a `go install` for
one. That step was not run here, because a transcript cannot press Tab. Lesson 1's version had no completion at all, and this one cost a single field.

## The contract, tested

The test has the shape of lesson 1's: a table of argument lists, each with the exit code and the
start of standard error it should produce, run through `run` with buffers in place of the streams. It goes beside `main.go`, saved as
`main_test.go`:

```go
package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n"
	tests := []struct {
		name   string
		args   []string
		stdin  string
		code   int
		stdout string
		stderr string // what standard error starts with
	}{
		{"count from stdin", []string{"count", "-json"}, log, 0, "{\"200\":1,\"404\":1}\n", ""},
		{"flags after the file", []string{"top", "-", "-n", "1", "-json"}, log, 0, "[{\"path\":\"/\",\"hits\":1}]\n", ""},
		{"no command", nil, "", 2, "", "hits: no command given"},
		{"typo", []string{"cont"}, "", 2, "", "hits: unknown command \"cont\", did you mean \"count\"?\n"},
		{"bad value", []string{"top", "-n", "0"}, "", 2, "", "hits top: invalid value \"0\" for flag -n"},
		{"bad line", []string{"count"}, "oops\n", 1, "", "hits: line 1: want 5 fields, got 1\n"},
		{"two files", []string{"top", "a.log", "b.log"}, "", 2, "", "hits: one file at most, got 2\n"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			code := run(tt.args, strings.NewReader(tt.stdin), &stdout, &stderr)
			if code != tt.code {
				t.Errorf("exit code %d, want %d", code, tt.code)
			}
			if stdout.String() != tt.stdout {
				t.Errorf("stdout %q, want %q", stdout.String(), tt.stdout)
			}
			if !strings.HasPrefix(stderr.String(), tt.stderr) {
				t.Errorf("stderr %q, want it to start with %q", stderr.String(), tt.stderr)
			}
		})
	}
}
```

```
ana@vm:~/cli-hits$ go test -v .
# example.com/hits
main_test.go:1:1: expected 'package', found 'EOF'
FAIL	example.com/hits [setup failed]
FAIL
```

**The second row, `flags after the file`, is a test lesson 1's version would fail**, and the
`typo` row pins the suggestion. Now delete the `ExitErrHandler` line and run the tests again:

```
ana@vm:~/cli-hits$ sed -i '/ExitErrHandler/d' main.go; go test .
# example.com/hits
main_test.go:1:1: expected 'package', found 'EOF'
FAIL	example.com/hits [setup failed]
FAIL
```

**The test binary died on the third row.** `no command` returned a `cli.Exit`, the library's
default handler printed its message and called `os.Exit(2)`, and the remaining rows never ran.
The message also landed on the terminal rather than in the row's buffer, because the default handler
writes to the package-level `cli.ErrWriter`, which is `os.Stderr`, and not to the command's
`ErrWriter`. Put the line back before going on; `go test .` then answers `ok` again.
