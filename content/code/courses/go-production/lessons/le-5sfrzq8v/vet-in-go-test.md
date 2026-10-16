---
title: The vet that `go test` runs for you
version: 1
---

You have probably run vet without typing it. **Before `go test` runs a single test, it vets the
package and its test files, and if vet reports anything the tests do not run.** It does not run all 35
analyzers: only the ones whose findings are so reliably real that failing a test run on them is never
a nuisance. The help names them, and so does the go command's own source:

```
ana@vm:~/vetted$ go help test | grep -A2 "That subset"
used. That subset is: atomic, bools, buildtag, directive, errorsas,
ifaceassert, nilfunc, printf, stdversion, stringintconv, and tests.
You can see the documentation for these and other vet tests via
ana@vm:~/vetted$ grep -A40 "defaultVetFlags = " "$(go env GOROOT)/src/cmd/go/internal/test/test.go" | grep -E "^\s+\"-" | tr -d "\t\"," | tr "\n" " "; echo
-atomic -bools -buildtag -directive -errorsas -ifaceassert -nilfunc -printf -slog -stdversion -stringintconv -tests 
```

The two lines do not agree, and **the second is the one that runs**. It is the list compiled into the
go command, read out of the toolchain's own source on your machine: twelve analyzers, where
`go help test` names eleven and leaves out `slog`. A test package with a malformed `slog.Info` call
fails `go test` on Go 1.27.1, whatever the help says. Everything else on the list is in both.

Of the analyzers section 03 used, only `printf` is on the list. `copylocks`, `lostcancel`,
`structtag`, `unusedresult`, `shift`, `assign` and `unreachable` are all off. `go help test` calls the subset "high-confidence",
and the bar is higher than vet's own: a check that stops somebody's tests over a false alarm teaches
them to switch the step off, which is the next part of this section.

## A test run that fails before any test runs

A package that reads a status code, with a typed error and a helper that asks an error which field
it came from, saved as `status/status.go`:

```go
// Package status reads the status field of a log line.
package status

import (
	"errors"
	"fmt"
	"strconv"
)

// Error says which field could not be read, and why.
type Error struct {
	Field string
	Err   error
}

func (e *Error) Error() string { return e.Field + ": " + e.Err.Error() }
func (e *Error) Unwrap() error { return e.Err }

// Parse reads an HTTP status code, which runs from 100 to 599.
func Parse(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, &Error{"status", err}
	}
	if n < 100 || n > 999 {
		return 0, fmt.Errorf("status %d out of range", n)
	}
	return n, nil
}

// Field names the field a parse error came from, or "" for any other error.
func Field(err error) string {
	var e *Error
	if errors.As(err, e) {
		return e.Field
	}
	return ""
}
```

And its tests, `status/status_test.go`:

```go
package status

import "testing"

func TestParse(t *testing.T) {
	if n, err := Parse("404"); n != 404 || err != nil {
		t.Errorf("Parse(%q) = %d, %v", "404", n, err)
	}
}

func TestparseRejects(t *testing.T) {
	for _, s := range []string{"abc", "99", "600"} {
		if _, err := Parse(s); err == nil {
			t.Errorf("Parse(%q) accepted it", s)
		}
	}
}
```

There are three bugs here, and `go test` reports two of them without running anything:

```
ana@vm:~/vetted$ go test ./status
# example.com/vetted/status
# [example.com/vetted/status]
status/status.go:34:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
status/status_test.go:11:6: TestparseRejects has malformed name: first letter after 'Test' must not be lowercase
FAIL	example.com/vetted/status [build failed]
FAIL
```

**`[build failed]` is how a vet failure looks inside `go test`**: the go command treats the vet step
as part of building the test binary, and the binary was never run. `errorsas` caught `Field` passing
`e`, a nil `*Error`, where `errors.As` needs a pointer to it. That call would panic the first time
anybody asked a real error which field it came from, and no test calls `Field`, so no test would have
found it. `tests` caught a name: `testing` runs functions called `Test` followed by something that
does not start with a lower-case letter, and `TestparseRejects` is not one of them.

## Why not `-vet=off`

`-vet=off` turns the step off, and it is the first thing people reach for when `go test` fails in a
way they did not expect. Here is what it buys:

```
ana@vm:~/vetted$ go test -vet=off -v ./status
=== RUN   TestParse
--- PASS: TestParse (0.00s)
PASS
ok  	example.com/vetted/status	0.003s
```

**`ok`, and one test.** The misnamed test was not run and nothing said so: no warning, no skipped
count, a green line. Fixing both findings is two `sed` commands, and the test that comes back to life
finds the third bug, the one vet could never have seen, because `999` is a perfectly legal number:

```
ana@vm:~/vetted$ sed -i "s/Testparse/TestParse/" status/status_test.go
ana@vm:~/vetted$ sed -i "s/errors.As(err, e)/errors.As(err, \&e)/" status/status.go
ana@vm:~/vetted$ go test ./status
--- FAIL: TestParseRejects (0.00s)
    status_test.go:14: Parse("600") accepted it
FAIL
FAIL	example.com/vetted/status	0.002s
FAIL
ana@vm:~/vetted$ sed -i "s/n > 999/n > 599/" status/status.go && go test ./status
ok  	example.com/vetted/status	0.011s
```

`Parse` accepted `600` because its range check said `999`. **With `-vet=off` that bug ships, behind a
green test run, protected by a test that exists and never runs.** That is the argument against the
flag: the checks `go test` runs were chosen so that a failure is always worth reading, so turning
them off trades a message you can act on for a bug you cannot see.

## The checks `go test` leaves to you

The other side of a curated list is that a green `go test` says nothing about the rest. `counter`, from
section 03, gets a test, `counter/main_test.go`, that calls `Add` from one goroutine:

```go
package main

import "testing"

func TestAdd(t *testing.T) {
	c := Counter{n: map[string]int{}}
	c.Add("/login")
	c.Add("/login")
	if got := c.n["/login"]; got != 2 {
		t.Errorf("got %d, want 2", got)
	}
}
```

```
ana@vm:~/vetted$ go test ./counter
ok  	example.com/vetted/counter	0.002s
ana@vm:~/vetted$ go test -vet=all ./counter
# example.com/vetted/counter
# [example.com/vetted/counter]
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
FAIL	example.com/vetted/counter [build failed]
FAIL
```

The test passes, because one goroutine never races with itself, and `copylocks` is not in the default
list, so `go test` is green on a type that crashes under load. **`-vet=all` makes `go test` run every
analyzer**, and then the same run fails. **That is why a project runs `go vet ./...` as a step of its
own, beside `go test ./...`.** The subset is what is safe to impose on every test run, and the full
suite is what a CI pipeline can afford to insist on.
