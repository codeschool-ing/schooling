---
title: "revive: style, by rules you choose"
version: 1
---

Style is the first row of lesson 7's table of what vet leaves out: **correct code written in a way
the next reader will trip over**. A missing doc comment on an exported function, a `context.Context`
that is not the first parameter, an error string that reads wrong when printed after another. None
of them is a bug, and on a team each one becomes a review comment somebody writes by hand, again,
every week. A style linter writes those comments instead, and `revive` is the one most Go projects
reach for.

## golint's successor, and what it inherited

For years the style linter was `golint`, from the Go project itself. Its README now opens with
"Golint is deprecated and frozen. There's no drop-in replacement for it, but tools such as
Staticcheck and `go vet` should be used instead." **revive's README answers that with its first
line: "Drop-in replacement of golint."** Both are true in their way. Run with no configuration,
revive applies golint's 18 rules, ported unchanged, and five of its own, 23 in all. What it adds is
everything golint never had: a configuration file, a severity per rule, rules that take arguments,
comments that switch a rule off, and 82 more rules that stay off until a configuration asks for
them.

`~/lint` still holds section 02's `report.go`, with its directives taken out. Install the pinned
release and run it:

```
ana@vm:~/lint$ go install github.com/mgechev/revive@v1.17.1 && revive -version
version 1.17.1
ana@vm:~/lint$ revive ./... | sort -V
internal/tally/report.go:15:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:15:27: exported func NewReport returns unexported type *tally.report, which can be annoying to use
internal/tally/report.go:40:24: context.Context should be the first parameter of a function
internal/tally/report.go:45:21: error strings should not be capitalized or end with punctuation or a newline
ana@vm:~/lint$ revive ./... > /dev/null; echo $?
0
ana@vm:~/lint$ revive -set_exit_status ./... > /dev/null; echo $?
1
```

The output goes through `sort -V`, which orders it by file, line and column. **revive checks each
rule in a goroutine of its own and prints findings as they arrive**, so two runs list the same lines
in different orders.

Four findings, and three are things staticcheck did not mention. `exported` wants a comment on
every exported name, where staticcheck's `ST1020` to `ST1022` judge only a comment that is there,
and are off by default anyway.
`unexported-return` says that `NewReport` returns a `*report`, a type the caller cannot name, so it
can hold the value but cannot write it into a struct field or a function signature of its own.
`context-as-argument` wants the context first, because that is where every reader looks for it.
The fourth, `error-strings`, is the same complaint as staticcheck's `ST1005`, in other words.

## A linter that never fails

Look at the two exit codes again. **revive found four things and exited 0**, and only
`-set_exit_status` changes that. Its defaults set both of the exit codes it can return to 0: one
used when the worst finding is a warning, one when it is an error. A CI step that runs plain `revive
./...` prints its findings into a log and passes, every time, which is lesson 6's `gofmt -l` trap
again with a different tool.

## A configuration file, printed whole

`revive.toml` decides which rules run, how serious each one is, and which exit code each severity
earns. Save it at the top of the module, `revive.toml`:

```toml
# revive.toml: the rules revive applies to this module, and which of them fail.
enable-default-rules = true
severity = "warning"
confidence = 0.8
error-code = 1
warning-code = 0

[rule.context-as-argument]
severity = "error"

[rule.unhandled-error]
severity = "error"
arguments = ['^fmt\.Fprint(f|ln)?$']

[rule.cognitive-complexity]
arguments = [7]
exclude = ["TEST"]
```

Line by line, from the top:

| setting | what it does |
|---|---|
| `enable-default-rules = true` | keeps the 23 defaults; **without it, naming any rule switches off every default not named** |
| `severity`, `confidence` | the severity of a rule that does not set its own, and how sure a rule must be before it reports |
| `error-code = 1`, `warning-code = 0` | an error fails the run, a warning is printed and passes |
| `context-as-argument` | a default rule, raised from warning to error |
| `unhandled-error` | a call whose error result is dropped; the argument is a list of regular expressions for functions to let off |
| `cognitive-complexity` | how hard a function is to follow, at most 7, and not in test files |

The first row is the trap in the file format. A `revive.toml` that only adds `unhandled-error`
looks like "the defaults plus one", and it is "one": `exported`, `error-strings` and the other
twenty-one stop running without a word. **The expression in `unhandled-error` has to match the whole
function name**, `fmt.Fprintf` and not just its start, which is why it ends in `$` and spells out the
three endings; `'^fmt\.Fprint'` alone lets nothing off. Writing to standard error in `main.go` is
what that list excuses, and nothing else.

```
ana@vm:~/lint$ revive -config revive.toml ./... | sort -V
internal/tally/report.go:15:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:15:27: exported func NewReport returns unexported type *tally.report, which can be annoying to use
internal/tally/report.go:40:24: context.Context should be the first parameter of a function
internal/tally/report.go:45:21: error strings should not be capitalized or end with punctuation or a newline
internal/tally/report.go:48:2: Unhandled error in call to function os.WriteFile
ana@vm:~/lint$ revive -config revive.toml ./... > /dev/null; echo $?
1
ana@vm:~/lint$ revive -config revive.toml -formatter ndjson ./... | grep -o '"Severity":"error","Failure":"[^"]*"' | sort
"Severity":"error","Failure":"Unhandled error in call to function os.WriteFile"
"Severity":"error","Failure":"context.Context should be the first parameter of a function"
```

**Five findings and exit status 1.** The new one is `os.WriteFile` in `Save`, the bug section 02's
staticcheck had no check for: the write can fail and the function returns `nil` anyway. Two of the
five are errors, and those two are what failed the run. The default output does not show severity,
and the `ndjson` formatter, one JSON object per finding, does: the `grep` picked out the two. `main_test.go` stayed out of it: `TestRun` has a cognitive complexity of 11, over the limit,
and `exclude = ["TEST"]` keeps the rule away from every `_test.go` file, where a table-driven test
is supposed to look like that.

## Switching a rule off for one line

revive's directives are comments too. `//revive:disable-next-line:RULE reason` covers the line
below; `//revive:disable:RULE` and `//revive:enable:RULE` bracket a stretch of a file. A reason is
optional by default, and the directive `specify-disable-reason`, set in the configuration, makes it
compulsory.

```
ana@vm:~/lint$ sed -i '/^func NewReport/i //revive:disable-next-line:unexported-return the type stays private until the API settles' internal/tally/report.go
ana@vm:~/lint$ revive -config revive.toml ./internal/... | sort -V
internal/tally/report.go:16:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:41:24: context.Context should be the first parameter of a function
internal/tally/report.go:46:21: error strings should not be capitalized or end with punctuation or a newline
internal/tally/report.go:49:2: Unhandled error in call to function os.WriteFile
```

**`unexported-return` is gone and the other four stay**, each one line lower, because the comment
added a line above them. The directive named one rule, so `exported`, on the same line of code,
still reports. Delete the directive line before section 04.

## Why a team picks it

Some of revive's 23 defaults overlap staticcheck's style family, `error-strings` and `ST1005` among
them, and the rest of its value is in the rules nobody else has and in the arguments they take: a
complexity limit, a maximum line length, a list of imports a package may not use, a header every
file must start with. **revive is where a team writes down its own conventions**, the ones that are
not the Go project's and not bugs. Most teams that do never run it on its own: section 04 runs the
same rules from inside `golangci-lint`, with one configuration file for every linter.
