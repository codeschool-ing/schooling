---
title: "`go test` as an everyday instrument"
version: 1
---

`go test` is a build as well. **For each package it compiles the package together with its
`_test.go` files into a test binary, runs that binary, and keeps the result in the build cache.**
`go-concurrency` lessons 25 and 26 taught how to write the tests. This section is about running
them the way you do fifty times a day: all of them, one of them, the fast ones, until the first
failure, and in a form a program can read. It needs a package with more than one test, so `tally`
gets its own.

## Tests for `tally`

`internal/tally/tally_test.go`, beside `tally.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/tally_test.go",
  "parts": [
    {
      "code": "package tally_test\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n\t\"testing\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "**The package is `tally_test`, not `tally`.** A test file may declare the package name with `_test` added, and then it is compiled as a separate package that imports `tally` like any other caller would. It sees only what is exported, which is what `go doc` will show in section 05."
    },
    {
      "code": "func TestParse(t *testing.T) {\n\ttests := []struct {\n\t\tname    string\n\t\tline    string\n\t\tstatus  int\n\t\twantErr string // what the error starts with; \"\" for none\n\t}{\n\t\t{\"good\", \"2026-10-01T09:00:01Z POST /api/users 404 115ms\", 404, \"\"},\n\t\t{\"short line\", \"GET / 200\", 0, \"want 5 fields, got 3\"},\n\t\t{\"bad status\", \"2026-10-01T09:00:01Z GET / OK 5ms\", 0, \"status: \"},\n\t\t{\"bad duration\", \"2026-10-01T09:00:01Z GET / 200 5\", 0, \"time: missing unit\"},\n\t}",
      "note": "A table of lines and what each one should produce, the shape of `go-concurrency` lesson 26. **Each row's `name` becomes a subtest name**, and the names were chosen so that `-run` can pick a group of them: two rows start with `bad`."
    },
    {
      "code": "\tfor _, tt := range tests {\n\t\tt.Run(tt.name, func(t *testing.T) {\n\t\t\te, err := tally.Parse(tt.line)\n\t\t\tif tt.wantErr != \"\" {\n\t\t\t\tif err == nil || !strings.HasPrefix(err.Error(), tt.wantErr) {\n\t\t\t\t\tt.Fatalf(\"error %v, want one starting %q\", err, tt.wantErr)\n\t\t\t\t}\n\t\t\t\treturn\n\t\t\t}\n\t\t\tif err != nil {\n\t\t\t\tt.Fatal(err)\n\t\t\t}\n\t\t\tif e.Status != tt.status {\n\t\t\t\tt.Errorf(\"status %d, want %d\", e.Status, tt.status)\n\t\t\t}\n\t\t})\n\t}\n}\n",
      "note": "`t.Run` starts one subtest per row. `t.Fatalf` ends that subtest only; the loop goes on to the next row."
    },
    {
      "code": "func TestTop(t *testing.T) {\n\ts := tally.Summary{ByPath: map[string]int{\"/b\": 2, \"/a\": 2, \"/c\": 5}}\n\tgot := fmt.Sprint(tally.Top(s, 2))\n\tif want := \"[{/c 5} {/a 2}]\"; got != want {\n\t\tt.Errorf(\"Top = %s, want %s\", got, want)\n\t}\n}\n",
      "note": "`Top` is checked on a `Summary` built by hand, with two paths tied at 2 so the alphabetical tie-break is part of the test."
    },
    {
      "code": "func TestCountMillion(t *testing.T) {\n\tif testing.Short() {\n\t\tt.Skip(\"a million lines; skipped with -short\")\n\t}\n\tvar b strings.Builder\n\tfor i := range 1_000_000 {\n\t\tfmt.Fprintf(&b, \"2026-10-01T09:00:01Z GET /p%d 200 5ms\\n\", i%100)\n\t}\n\ts, err := tally.Count(strings.NewReader(b.String()))\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif s.Lines != 1_000_000 || len(s.ByPath) != 100 {\n\t\tt.Errorf(\"%d lines and %d paths, want 1000000 and 100\", s.Lines, len(s.ByPath))\n\t}\n}\n",
      "note": "**A test that knows it is slow asks `testing.Short()`** and skips itself when the run was started with `-short`. This one builds a million lines in memory and counts them."
    },
    {
      "code": "func ExampleTop() {\n\tlog := \"2026-10-01T09:00:01Z GET /login 200 5ms\\n\" +\n\t\t\"2026-10-01T09:00:02Z GET / 200 3ms\\n\" +\n\t\t\"2026-10-01T09:00:03Z POST /login 401 9ms\\n\"\n\ts, err := tally.Count(strings.NewReader(log))\n\tif err != nil {\n\t\tfmt.Println(err)\n\t\treturn\n\t}\n\tfor _, r := range tally.Top(s, 2) {\n\t\tfmt.Println(r.Path, r.Hits)\n\t}\n\t// Output:\n\t// /login 2\n\t// / 1\n}",
      "note": "**An example is a test whose expected output is the `// Output:` comment.** `go test` runs it and compares what it printed, line by line; `go doc` lists it beside `Top`."
    }
  ]
}
```

## All of them, and the cache

`./...` works for `go test` as it does for `go build`, so one command tests the whole module. Run
twice:

```
ana@vm:~/daily$ go test ./...
ok  	example.com/hits	0.006s
ok  	example.com/hits/internal/tally	0.483s
?   	example.com/hits/tools/genlog	[no test files]
ana@vm:~/daily$ go test ./...
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	(cached)
?   	example.com/hits/tools/genlog	[no test files]
ana@vm:~/daily$ go test -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.502s
```

`genlog` has no test files and says so with `?`. The `tally` tests took **0.483 seconds**, nearly
all of it the million lines, and the second time the line said **`(cached)`**: nothing was compiled
and nothing ran. The go command found the same test binary and the same flags in its cache, and
printed the output it had stored.

**A cached result is a past result, and it is only as good as the inputs the cache key sees**: the
code, the flags, and for a test that opens files inside the module or reads environment variables,
those files and variables. A test that talks to a database or reads the clock is cached as if its answer could
not change.
`-count=1` is the idiomatic way to say "really run it", and it ran in 0.502 seconds. Most of the
everyday flags keep the cache in use, and `go help test` lists them: `-run`, `-short`, `-v`,
`-failfast`, `-timeout` and a few more. And `go test` with no package at all, the "local directory
mode" of that help text, never caches.

## The fast ones, a list, and a choice

`-short` sets a flag that tests read with `testing.Short()`. `go test` does nothing else with it,
so a test is short only if somebody wrote it to be:

```
ana@vm:~/daily$ go test -short -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/good
=== RUN   TestParse/short_line
=== RUN   TestParse/bad_status
=== RUN   TestParse/bad_duration
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/good (0.00s)
    --- PASS: TestParse/short_line (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
    --- PASS: TestParse/bad_duration (0.00s)
=== RUN   TestTop
--- PASS: TestTop (0.00s)
=== RUN   TestCountMillion
    tally_test.go:52: a million lines; skipped with -short
--- SKIP: TestCountMillion (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.003s
ana@vm:~/daily$ go test -list . ./internal/tally
TestParse
TestTop
TestCountMillion
ExampleTop
ok  	example.com/hits/internal/tally	0.002s
```

**`TestCountMillion` skipped itself, with its reason, and the package took 0.003 seconds** instead
of half a second. A pre-commit hook runs `-short`; CI runs everything. `-list` takes a regular
expression and prints the top-level tests and examples that match without running any of them; a
subtest is created only when its parent runs, so it cannot be listed.

`-run` takes a regular expression too, and it is the flag used most. **A slash splits it into one
expression per level of subtest**, so `TestParse/bad` means "a top-level test matching `TestParse`,
then a subtest matching `bad`":

```
ana@vm:~/daily$ go test -run TestParse/bad -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/bad_status
=== RUN   TestParse/bad_duration
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
    --- PASS: TestParse/bad_duration (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.004s
ana@vm:~/daily$ go test -run "TestParse/bad status" -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/bad_status
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.002s
ana@vm:~/daily$ go test -run Top -v ./internal/tally
=== RUN   TestTop
--- PASS: TestTop (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.002s
```

The table's names became subtest names with each space turned into an underscore, `bad_status`.
The second command shows that `-run` applies the same rewriting to the pattern, so the name as it
is written in the table works too. **The expressions are not anchored**: `Top` matched `TestTop` and
also `ExampleTop`, because an example is a test as far as `-run` is concerned. `-run '^TestTop$'`
is the way to say exactly one.

## Stopping at the first failure

To see a failure, Ana breaks one row on purpose, changing the status the `good` row expects from
404 to 403, and runs the package twice:

```
ana@vm:~/daily$ sed -i 's/115ms", 404/115ms", 403/' internal/tally/tally_test.go
ana@vm:~/daily$ go test ./internal/tally
--- FAIL: TestParse (0.00s)
    --- FAIL: TestParse/good (0.00s)
        tally_test.go:36: status 404, want 403
FAIL
FAIL	example.com/hits/internal/tally	0.473s
FAIL
ana@vm:~/daily$ go test -failfast -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/good
    tally_test.go:36: status 404, want 403
--- FAIL: TestParse (0.00s)
    --- FAIL: TestParse/good (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.004s
FAIL
ana@vm:~/daily$ sed -i 's/115ms", 403/115ms", 404/' internal/tally/tally_test.go
```

The first run printed the failure and nothing else about the tests that passed, which is what
`go test` does for a package listed by name without `-v`. It also ran everything, million lines
included, and took **0.473 seconds** to report a failure in the first row of the first test.
**`-failfast` starts no new test after the first failure**: the other three rows of `TestParse`,
`TestTop` and `TestCountMillion` never started, and the run took 0.004 seconds. The example still
ran. `go help testflag` describes the flag as stopping tests, and in this release an example is
started anyway, which is worth knowing before a slow one ends up in a package. The exit status is 1
either way, and the last `sed` puts the row back.

## Output for a program, and coverage

`-json` turns the run into one JSON object per event, which is what CI systems and editors read.
The `Time` field opens every line with the date of the run, so `cut` drops it here:

```
ana@vm:~/daily$ go test -json -run TestTop ./internal/tally | cut -d, -f2-
"Action":"start","Package":"example.com/hits/internal/tally"}
"Action":"run","Package":"example.com/hits/internal/tally","Test":"TestTop"}
"Action":"output","Package":"example.com/hits/internal/tally","Test":"TestTop","Output":"=== RUN   TestTop\n","OutputType":"frame"}
"Action":"output","Package":"example.com/hits/internal/tally","Test":"TestTop","Output":"--- PASS: TestTop (0.00s)\n","OutputType":"frame"}
"Action":"pass","Package":"example.com/hits/internal/tally","Test":"TestTop","Elapsed":0}
"Action":"output","Package":"example.com/hits/internal/tally","Output":"PASS\n","OutputType":"frame"}
"Action":"output","Package":"example.com/hits/internal/tally","Output":"ok  \texample.com/hits/internal/tally\t0.003s\n"}
"Action":"pass","Package":"example.com/hits/internal/tally","Elapsed":0.004}
```

Every line names its package and, where there is one, its test; `"Action"` says what happened:
`start`, `run`, `output`, `pass`, `fail`, `skip`. A tool counting failures across a thousand
packages filters on `"Action":"fail"` instead of parsing the text a person reads.

`-cover` adds a percentage to each package's line. `go-concurrency` lesson 30 covers coverage
properly; here it is one more flag of the same command:

```
ana@vm:~/daily$ go test -cover ./...
ok  	example.com/hits	0.003s	coverage: 49.3% of statements
ok  	example.com/hits/internal/tally	0.388s	coverage: 93.3% of statements
	example.com/hits/tools/genlog		coverage: 0.0% of statements
```

**93.3% of `tally`'s statements ran** under its own tests, and 49.3% of `main`'s under `TestRun`.
`genlog`, with no tests at all, is reported at 0.0% rather than left out, so a package nobody tested
stands out in the list.
