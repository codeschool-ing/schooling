---
title: Two streams and an exit code
version: 1
---

A command-line program has three ways to talk back, and **a script reading it uses each one for a
different question**. Standard output answers "what did you find". Standard error answers "what went
wrong", for the person watching. The exit code answers "did it work", for the program that started
it. Mixing them up does not break the tool when a person runs it by hand; it breaks it the first time
somebody puts it in a pipeline, a cron job or a CI step.

## Results to one stream, complaints to the other

Every message `hits` prints about a problem goes to `stderr`, which `run` receives as a parameter.
The difference is invisible in a terminal, where both streams land on the same screen, and obvious
the moment one of them is redirected:

```
ana@vm:~/hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
ana@vm:~/hits$ ./hits count nope.log 2>/dev/null; echo $?
1
ana@vm:~/hits$ ./hits top a.log b.log 2>&1 >/dev/null | wc -l
1
```

`2>/dev/null` threw standard error away, and the message went with it while the exit code stayed.
The third line is the opposite trick: it points standard error at the pipe and standard output at
nothing, and `wc` counted the one line of complaint. **If that complaint had gone to standard output,
the next program in the pipeline would have read it as data**, and a report built from `hits top`
would have a row reading `hits: one file at most, got 2`.

The message starts with the program's name for the same reason. In a pipeline of four tools, a line
on the screen saying `open nope.log: no such file or directory` does not say who failed to open it.

## The exit code is the answer to "did it work"

| code | what `hits` means by it | examples above |
|---|---|---|
| `0` | it did what was asked | a table, a JSON array, help that was asked for |
| `1` | it was called correctly and the run failed | a file that will not open, a line that will not parse |
| `2` | it was called wrongly | no command, an unknown one, a bad flag, two files |

Only `0` is universal: it means success to every shell, every `make`, every CI system. The split
between 1 and 2 is a convention the flag package follows, `grep` follows and `hits` follows. It
is worth keeping because a script can tell "fix your invocation" from "fix your data" without reading
a word of English. A shell script uses it directly, in `if ./hits count "$f"; then` or under
`set -e`, which stops a script at the first command that returns anything but 0.

## Reading standard input

With no file, or with `-`, `hits` reads standard input, which lets it sit at the end of a pipe:

```
ana@vm:~/hits$ echo "not a log line" | ./hits count; echo $?
hits: line 1: want 5 fields, got 4
1
ana@vm:~/hits$ go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2
path             requests
/static/app.css  137
/api/users       135
ana@vm:~/hits$ ./hits count -json - < access.log
{"200":7554,"201":1256,"204":1248,"301":1192,"304":1229,"400":1223,"401":1226,"404":2549,"500":1269,"503":1254}
```

The error names the line, because the input might be a million lines long and arrive from a program
that has already gone. `genlog` and `hits` ran at the same time in the second command, one writing
and the other reading, and no file was made. The third reads the same file through the shell's `<`,
and the counts match section 04's table exactly.

## When the reader stops early

A pipe can also close from the far end. `head` reads the lines it wants and exits, and the program
writing into the pipe finds nobody listening:

```
ana@vm:~/hits$ ./hits top -n 8 access.log | head -2; echo ${PIPESTATUS[@]}
path             requests
/login           2576
0 0
ana@vm:~/hits$ go build -o genlog ./tools/genlog && ./genlog -n 1000000 | head -1; echo ${PIPESTATUS[@]}
2026-10-01T09:00:01Z POST /api/users 404 115ms
141 0
```

`PIPESTATUS` holds the exit code of every command in the last pipeline. The `hits` table was small
enough to be written whole before `head` exited, so both are 0. `genlog` was still writing its
millionth line when `head` left, and its status is **141**, which is 128 plus 13, the number of the
signal `SIGPIPE`. That is the Go runtime's rule for standard output and standard error: a write to a
pipe whose reader has gone kills the program with `SIGPIPE`, quietly, the way `cat` and every other
Unix tool behave. On any other descriptor a broken pipe is an ordinary error, and so is a full disk on
any descriptor at all; those are the errors `flush` and `encode` report.

## The payoff of `run`

`main` hands `run` the arguments and the three streams instead of letting it reach for `os.Args` and
`os.Stdout`. That costs four parameters, and it buys a command line you can test as an ordinary
function, with strings in and strings out. `main_test.go`, beside `main.go`:

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
		{"no command", nil, "", 2, "", "usage: hits"},
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
ana@vm:~/hits$ go test -v .
=== RUN   TestRun
=== RUN   TestRun/count_from_stdin
=== RUN   TestRun/no_command
=== RUN   TestRun/bad_line
=== RUN   TestRun/two_files
--- PASS: TestRun (0.00s)
    --- PASS: TestRun/count_from_stdin (0.00s)
    --- PASS: TestRun/no_command (0.00s)
    --- PASS: TestRun/bad_line (0.00s)
    --- PASS: TestRun/two_files (0.00s)
PASS
ok  	example.com/hits	0.003s
```

It is the table-driven shape `go-concurrency` lesson 26 taught, with one row per contract the tool
makes: the stream each thing goes to and the exit code that comes with it. **No process was started
and no file was written**, so it runs in milliseconds and in parallel with everything else. A
program whose `main` does the work itself can only be tested by building it and running it, and
that is a test nobody writes for the error paths.
