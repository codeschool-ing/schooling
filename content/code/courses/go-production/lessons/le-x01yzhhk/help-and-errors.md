---
title: Help, mistakes and the exit code
version: 1
---

Cobra writes the help and finds the mistakes. **It does not decide the exit code**: `Execute`
returns an error or `nil`, and what the process exits with is up to `main`. The generator's template
settles it in the bluntest way, with `os.Exit(1)` for any error at all, which would make a typo and
a missing file look the same to a script. Lesson 1 section 05 promised more than that, three codes
with three meanings, and this section keeps the promise.

## Help that nobody wrote

Every `Use`, `Short` and `Long` in `main.go` is a sentence somebody wrote once. Cobra arranges them,
for the root and for each command:

```
ana@vm:~/cobra-hits$ ./hits --help
hits reads an access log, one request per line, and counts it.
With no file, or with -, it reads standard input.

Usage:
  hits [flags]
  hits [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  count       Requests per status code
  help        Help about any command
  top         The paths with the most requests

Flags:
  -h, --help   help for hits
      --json   print JSON instead of a table

Use "hits [command] --help" for more information about a command.
ana@vm:~/cobra-hits$ ./hits help top | head -4
The paths with the most requests

Usage:
  hits top [file] [flags]
```

The commands are listed alphabetically with their `Short`, and two of the four were never written:
**`help` and `completion` are added by Cobra to any root that has subcommands.** `hits help top`
prints `top`'s own help, the same as `hits top --help` in section 03, which is the second item on
lesson 1's list of what was missing. Lesson 1's hand-written usage text, its `case "help"` and its
`-h` handling are gone from the program.

## Mistakes, and who made them

The same mistakes lesson 1 section 04 made, against the new program:

```
ana@vm:~/cobra-hits$ ./hits cont access.log; echo $?
hits: unknown command "cont" for "hits"

Did you mean this?
	count

Run 'hits --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits; echo $?
hits: which command? count or top
Run 'hits --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits top -n five access.log; echo $?
hits: invalid argument "five" for "-n, --number" flag: strconv.ParseInt: parsing "five": invalid syntax
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits top a.log b.log; echo $?
hits: accepts at most 1 arg(s), received 2
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
```

**`cont` now gets a suggestion**, and the first item on lesson 1's list is crossed off. Cobra
compares the unknown word with every command's name and offers each one within two edits of it, or
whose name starts with it; `cont` is one letter short of `count`. The wording of the other messages is Cobra's
and pflag's, more technical than lesson 1's. `accepts at most 1 arg(s)` comes from
`cobra.MaximumNArgs(1)`, which checked the arguments before `RunE` ran. And every line went to
standard error, every mistake ended in 2 and the file that would not open ended in 1, **as the table
in lesson 1 section 05 says it should**.

## How `run` tells them apart

All five errors came back from `ExecuteC` as plain `error` values, and nothing in Cobra marks one as
a usage mistake. The distinction has to come from the other side. **Every error a command's `RunE`
returns for a failed run is wrapped in `runError`; anything else came from Cobra or pflag, before
any `RunE` started, and is a mistake in the command line.** So `run` asks one question:

```go
	var failed runError
	if errors.As(err, &failed) {
		return 1
	}
```

`errors.As` looks through the chain of wrapped errors for a `runError`, which is why `runError` has
an `Unwrap` method: a caller can still ask `errors.Is(err, fs.ErrNotExist)` of the error inside it.
An unknown command, an unknown flag, a value that does not parse and too many arguments all lack the
wrapper and get 2, with a hint naming the command that refused them. That hint copies Cobra's own
wording, `Run 'hits top --help' for usage.`; `ExecuteC` returned `top` as well as the error, which
is how `run` knows what to name.

The bare `./hits` needed one more decision. **A root with subcommands and no `RunE` of its own
prints its help and returns `nil`**, so Cobra's default answer is exit status 0. Giving the root a
`RunE` that returns a plain error turns that into a usage mistake and keeps lesson 1's 2. The price
shows in the help above: Cobra now believes `hits` can run on its own, and lists `hits [flags]` as a
usage line.

## Why both `Silence` fields are set

Left alone, Cobra prints an error itself, as `Error: ` followed by the message, and then the
command's whole usage listing. `run` sets `SilenceErrors` and `SilenceUsage` and prints the one
line it wants, for a reason that is easy to miss. **Cobra prints the usage with `Println`, which
writes to the writer given to `SetOut`, and only falls back to standard error when there is none.**
`run` gives the tree its standard output, so the listing after a bad flag or a wrong number of
arguments would have gone to standard output, into whatever pipe or file the results were meant for. Silencing both and printing
in `run` puts every complaint on standard error, where lesson 1 section 05 put them.

One gap is left, and it is Cobra's:

```
ana@vm:~/cobra-hits$ ./hits help cont 2>/dev/null | head -2; echo ${PIPESTATUS[0]}
Unknown help topic [`cont`]
Usage:
0
```

The built-in `help` command answers an unknown topic on standard output, with exit status 0, and
`2>/dev/null` did not hide it. It is the one path of this program that breaks the contract, and the
fix would be a `help` command of your own, set with `SetHelpCommand`. `hits` leaves it, because the
caller asked for help and got it, if not the help they meant.

## The test, rewritten

`run` kept lesson 1's signature, so lesson 1's table test carries over almost line for line. The
rows change to what Cobra says, and three are new: flags after the file, the typo with its
suggestion, and lesson 1's `-json`. `main_test.go`, beside `main.go`:

```go
package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
		"2026-10-01T09:00:03Z POST /login 200 9ms\n"
	tests := []struct {
		name   string
		args   []string
		stdin  string
		code   int
		stdout string
		stderr string // what standard error starts with
	}{
		{"count from stdin", []string{"count", "--json"}, log, 0, "{\"200\":2,\"404\":1}\n", ""},
		{"flags after the file", []string{"top", "-", "-n", "1", "--json"}, log, 0, "[{\"path\":\"/login\",\"hits\":2}]\n", ""},
		{"no command", []string{}, "", 2, "", "hits: which command?"}, // nil would read os.Args
		{"typo", []string{"cont"}, "", 2, "", "hits: unknown command \"cont\" for \"hits\"\n\nDid you mean this?\n\tcount\n"},
		{"old flag spelling", []string{"top", "-json"}, log, 2, "", "hits: unknown shorthand flag: 'j' in -json\n"},
		{"bad line", []string{"count"}, "oops\n", 1, "", "hits: line 1: want 5 fields, got 1\n"},
		{"two files", []string{"top", "a.log", "b.log"}, "", 2, "", "hits: accepts at most 1 arg(s), received 2\n"},
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
ana@vm:~/cobra-hits$ go test -v .
=== RUN   TestRun
=== RUN   TestRun/count_from_stdin
=== RUN   TestRun/flags_after_the_file
=== RUN   TestRun/no_command
=== RUN   TestRun/typo
=== RUN   TestRun/old_flag_spelling
=== RUN   TestRun/bad_line
=== RUN   TestRun/two_files
--- PASS: TestRun (0.00s)
    --- PASS: TestRun/count_from_stdin (0.00s)
    --- PASS: TestRun/flags_after_the_file (0.00s)
    --- PASS: TestRun/no_command (0.00s)
    --- PASS: TestRun/typo (0.00s)
    --- PASS: TestRun/old_flag_spelling (0.00s)
    --- PASS: TestRun/bad_line (0.00s)
    --- PASS: TestRun/two_files (0.00s)
PASS
ok  	example.com/hits	0.009s
```

**Each row builds a new tree**, because `run` calls `newRootCmd` every time. That is the reason
section 02 gave for constructors over package-level commands: `top`'s `n` is a fresh variable in
every row, so the row that passes `-n 1` cannot leave 1 behind for the next. Two details in the
table are Cobra's. The `no command` row passes an empty slice rather than `nil`, because
`ExecuteC` treats `nil` as "no arguments were set" and reads `os.Args` instead, which inside a test
binary holds the test runner's own flags. And `-` in the second row is standard input: pflag treats a
lone dash as an argument, not a flag.
