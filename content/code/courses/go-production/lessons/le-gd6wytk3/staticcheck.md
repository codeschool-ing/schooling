---
title: "staticcheck: the bugs vet lets through"
version: 1
---

Lesson 7 ended with a table of what `go vet` will never tell you, and its precision criterion is
the reason: a check that is right nine times in ten is not good enough for vet. **`staticcheck` is a
suite of analyzers on the same framework that makes a different trade**: it reports a bug that is
very likely rather than certain, code with a simpler spelling, a call to something deprecated, and
code nobody calls. It still aims for few false alarms, which is what lets a project run it with its
defaults and leave it on in CI.

## A file vet passes

Everything in this lesson works in one module, `~/lint`, holding the four files lesson 1 prints,
`tools/genlog/main.go`, `internal/tally/tally.go`, `main.go` and `main_test.go`, and made with
`go mod init example.com/hits`. Install the pinned release and run it over `hits` as it stands:

```
ana@vm:~/lint$ go install honnef.co/go/tools/cmd/staticcheck@v0.8.2 && staticcheck -version
staticcheck 2026.2.2 (0.8.2)
ana@vm:~/lint$ go vet ./... && staticcheck ./...; echo $?
0
```

`go install` printed nothing because the module was already in the cache here; on a first install it
lists what it downloads. **`hits` is clean**: vet and staticcheck both exit 0 and say nothing, which
is a fair reading of a small program written with care.

To have something to find, give `hits` a file of the kind every program grows sooner or later: a
summary that can be saved to disk and read back. It compiles, and every line of it is something
people really write. Save it as `internal/tally/report.go`:

```go
package tally

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

type report struct {
	lines, errors, api int
}

func NewReport(s Summary) *report {
	r := &report{lines: s.Lines}
	for status, n := range s.ByStatus {
		if status >= 500 {
			r.errors += n
		}
	}
	for path, n := range s.ByPath {
		if strings.Index(path, "/api/") != -1 {
			r.api += n
		}
	}
	return r
}

// ErrorShare is the share of requests that failed on the server.
func (r *report) ErrorShare() float64 {
	n := uint(r.lines)
	if n >= 0 {
		return float64(r.errors) / float64(n)
	}
	return 0
}

// Save writes the report to path, unless ctx is already done.
func Save(path string, ctx context.Context, r *report) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if r.lines == 0 {
		return fmt.Errorf("Nothing to save.")
	}
	text := fmt.Sprintf("lines %d\nerrors %d\napi %d\n", r.lines, r.errors, r.api)
	os.WriteFile(path, []byte(text), 0o644)
	return nil
}

// ToCsv returns the report as one line of comma-separated values.
func (r *report) ToCsv() string {
	return fmt.Sprintf("%d,%d,%d", r.lines, r.errors, r.api)
}

// Load reads back what Save wrote.
func Load(path string) (string, error) {
	data, err := ioutil.ReadFile(path)
	return string(data), err
}

func percent(part, whole int) float64 {
	return 100 * float64(part) / float64(whole)
}
```

```
ana@vm:~/lint$ go vet ./...; echo $?
0
ana@vm:~/lint$ staticcheck ./...; echo $?
internal/tally/report.go:6:2: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details.  (SA1019)
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:45:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:45:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:63:6: func percent is unused (U1000)
1
```

**Vet passed it, and staticcheck found five problems on six lines.** Each line ends with the name of
the check that produced it, and the letters before the digits are the family the check belongs to:

| family | what it looks for | here |
|---|---|---|
| `SA`, staticcheck | code that is wrong, or very likely to be | `SA1019`, a deprecated package; `SA4003`, a condition that is always true |
| `S`, simple | code that has a shorter way to say the same thing | `S1003`, `strings.Index(...) != -1` for `strings.Contains` |
| `ST`, stylecheck | conventions the Go project writes down | `ST1005`, an error string with a capital and a full stop |
| `U1000`, unused | functions, types, fields and constants nothing uses | `percent` |

**`SA4003` is the one worth a bug report.** `n` is a `uint`, so `n >= 0` holds for every value it
can have, and the guard against dividing by zero guards nothing. The author meant `n > 0`. With an
empty log, `ErrorShare` divides 0.0 by 0.0, and floating-point division by zero does not panic in
Go: it returns `NaN`, which then travels into whatever prints or averages the share. `SA1019` is
less urgent and just as real: `io/ioutil` still works, and its own documentation says new code
should use `io` and `os`, which is what the message quotes.

The other three are not bugs. `S1003` and `ST1005` are about reading: `strings.Contains` says what
the line means, and an error string is usually printed after something else, as in
`hits: Nothing to save.`, where a capital in the middle of a line reads as a mistake. **`U1000`
is about weight**: a function nobody calls still has to be read, compiled and kept working.

## 149 checks, and the eight left off

`-list-checks` prints every check the program knows, one a line, and the first two characters are
enough to count the families:

```
ana@vm:~/lint$ staticcheck -list-checks | wc -l
149
ana@vm:~/lint$ staticcheck -list-checks | cut -c1-2 | sort | uniq -c
     35 S1
     95 SA
     18 ST
      1 U1
ana@vm:~/lint$ staticcheck -explain SA4003
Comparing unsigned values against negative values is pointless

Available since
    2017.1

Online documentation
    https://staticcheck.dev/docs/checks#SA4003
```

**Four families, 149 checks.** A fifth, `QF` for quick fix, exists in the same project and is
missing from the list on purpose: those are refactorings an editor offers on a line, through
`gopls`, and `cmd/staticcheck` registers them only behind a debugging flag. `-explain` prints what
a check is for and where its full page lives, which is the quickest way to decide whether a line in
a CI log is worth arguing with.

**Not all 149 run by default.** Eight are off, because they flag code that many projects write on
purpose. `ST1000` is a missing or misshapen package comment, `ST1003` a name such as `ToCsv` that
breaks Go's initialism convention, and `ST1016` methods whose receivers have different names.
`ST1020` to `ST1022` report doc comments that do not start with the name they document, `ST1023` a
variable declared with a type its value already states, and `SA9003` an empty branch. The rest are
on, and that default is the point: **a check that is on for every project is one whose false alarms
the maintainers have had to answer for**.

## Choosing the checks

The `-checks` flag takes a list in which `inherit` means "whatever was in force already", a name
adds a check and a name with a minus takes one away. Patterns work too: `ST*` is the whole style
family.

```
ana@vm:~/lint$ staticcheck -checks=inherit,-ST1005 ./internal/tally; echo $?
internal/tally/report.go:6:2: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details.  (SA1019)
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:63:6: func percent is unused (U1000)
1
```

**A list on the command line is a list every person and every CI job has to type the same way.** The
file `staticcheck.conf` holds it instead. Staticcheck looks for one in the directory of each package
and in every directory above it, and the nearest one wins; `inherit` in it means "what the file
above said", or the defaults at the top. Save this one at the top of the module, `staticcheck.conf`:

```toml
# staticcheck.conf: read from the package's directory and every one above it.
checks = ["inherit", "ST1003"]
initialisms = ["inherit", "CSV"]
```

It turns on `ST1003` and adds `CSV` to the list of initialisms the check knows, which starts with
`API`, `HTTP`, `ID`, `JSON`, `URL` and three dozen others, but not `CSV`:

```
ana@vm:~/lint$ staticcheck ./... | grep -v SA1019
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:45:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:45:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:53:18: method ToCsv should be ToCSV (ST1003)
internal/tally/report.go:63:6: func percent is unused (U1000)
```

The `grep` takes the long `SA1019` line out of the way. **`ToCsv` was invisible to the defaults and
is reported now**, because the file switched on a check and taught it one word.

## Silencing one line

Some findings are right in general and wrong for one line. Staticcheck's answer is a comment of
the form `//lint:ignore CHECK reason`, placed on the line above the one it excuses, and **the reason
is compulsory**: a directive without one is refused with
`malformed linter directive; missing the required reason field?`. Here are two, put in with `sed`,
one where the finding is and one on the line above a loop that contains it:

```
ana@vm:~/lint$ sed -i '/^func percent/i //lint:ignore U1000 kept for the -percent flag of the next release' internal/tally/report.go
ana@vm:~/lint$ sed -i '/for path, n := range/i //lint:ignore S1003 a loop over paths' internal/tally/report.go
ana@vm:~/lint$ staticcheck ./... | grep -v SA1019
internal/tally/report.go:22:1: this linter directive didn't match anything; should it be removed? (staticcheck)
internal/tally/report.go:24:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:34:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:46:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:46:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:54:18: method ToCsv should be ToCSV (ST1003)
```

**`percent` is gone, and the second directive is reported as matching nothing.** `U1000` is reported
on the line `func percent` starts on, so the comment above it excused it. `S1003` is reported on
the `if` inside the loop, two lines below its directive, and a directive covers exactly one line,
so it excused nothing and staticcheck said so. That warning is worth having: a directive left
behind after the code under it was fixed or moved would otherwise go on promising something it no
longer does. For a whole file, `//lint:file-ignore CHECK reason` does the same anywhere in the
file. Delete both directive lines and `staticcheck.conf` before section 03, which starts from the file
as printed.
