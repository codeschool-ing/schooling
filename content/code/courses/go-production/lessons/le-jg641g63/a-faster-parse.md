---
title: A faster Parse
version: 1
---

The profile has said three things. `strings.Fields` takes two thirds of `Parse`; nearly half of its
cost is allocating the slice it returns and the write barriers that filling it needs; and the
timestamp, the usual suspect, is a quarter of that. **The change worth making is the one that removes
the slice**, and it has to leave every answer `Parse` gives exactly as it was, because `hits` is
correct today and a faster wrong program is not an improvement.

## Numbers to beat, first

Before touching the code, Ana keeps the benchmark's current results in a file, ten runs of it,
because one run of a benchmark on a shared machine is one sample of a noisy number:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchmem -count 10 ./internal/tally > old.txt
```

`-count 10` runs the benchmark ten times; `-benchmem` keeps the memory columns. Section 06 compares
this file with the one written after the change.

## What `strings.Fields` does that `Parse` does not need

`strings.Fields` splits on any run of white space, as Unicode defines it, and returns a new slice
holding however many fields it found. `genlog`'s lines, like most access logs, have exactly five
fields separated by single spaces, in printable ASCII. So the plan is a function that **handles only
that plain case, without allocating, and declines everything else**, and a `Parse` that asks it first
and falls back to `strings.Fields` when it declines. The fallback keeps every odd line on the old,
known-good path. In `~/prof`, save it as `internal/tally/split.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/split.go",
  "parts": [
    {
      "code": "package tally\n\n// split5 cuts line into five fields at single spaces, without allocating.\n// It answers only for the plain case: printable ASCII, one space between\n// fields and none at either end. For anything else ok is false, and Parse\n// asks strings.Fields, which knows every kind of white space.\nfunc split5(line string) (f [5]string, ok bool) {",
      "note": "**A new file in the same package**, so nothing outside `tally` sees `split5`. It returns an array of five strings, a fixed-size value that lives in the caller's frame, where `strings.Fields` returns a slice it had to allocate on the heap."
    },
    {
      "code": "\tn, start := 0, 0\n\tfor i := 0; i < len(line); i++ {\n\t\tswitch c := line[i]; {\n\t\tcase c == ' ':\n\t\t\tif i == start || n == 4 {\n\t\t\t\treturn f, false\n\t\t\t}\n\t\t\tf[n] = line[start:i]\n\t\t\tn, start = n+1, i+1\n\t\tcase c < '!' || c > '~':\n\t\t\treturn f, false\n\t\t}\n\t}",
      "note": "One pass over the bytes. A space ends a field: an empty field (two spaces, or one at the start) or a fifth space means the line is not the plain case. **Any byte outside `!` to `~` also declines**: that range is printable ASCII, and outside it live the tab, the newline and every byte of a multi-byte character, including the Unicode spaces `strings.Fields` would split on."
    },
    {
      "code": "\tif n != 4 || start == len(line) {\n\t\treturn f, false\n\t}\n\tf[4] = line[start:]\n\treturn f, true\n}",
      "note": "Exactly four spaces seen, and something after the last one: the fifth field is the rest of the line. The strings in `f` are slices of `line` itself, so nothing was copied."
    }
  ]
}
```


And `Parse` changes in its first lines only. `internal/tally/tally.go`, in full:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/tally.go",
  "parts": [
    {
      "code": "// Package tally reads the lines of an access log and counts them.\npackage tally\n\nimport (\n\t\"bufio\"\n\t\"cmp\"\n\t\"fmt\"\n\t\"io\"\n\t\"slices\"\n\t\"strconv\"\n\t\"strings\"\n\t\"time\"\n)\n\n// Entry is one line of the log.\ntype Entry struct {\n\tTime     time.Time\n\tMethod   string\n\tPath     string\n\tStatus   int\n\tDuration time.Duration\n}\n",
      "note": "Unchanged from lesson 1, imports included: `strings` is still needed, for the lines `split5` declines."
    },
    {
      "code": "// Parse reads one line: a time, a method, a path, a status and a duration,\n// separated by spaces.\nfunc Parse(line string) (Entry, error) {\n\tf, ok := split5(line)\n\tif !ok {\n\t\tall := strings.Fields(line)\n\t\tif len(all) != 5 {\n\t\t\treturn Entry{}, fmt.Errorf(\"want 5 fields, got %d\", len(all))\n\t\t}\n\t\tf = [5]string(all)\n\t}\n\tt, err := time.Parse(time.RFC3339, f[0])\n\tif err != nil {\n\t\treturn Entry{}, err\n\t}\n\tstatus, err := strconv.Atoi(f[3])\n\tif err != nil {\n\t\treturn Entry{}, fmt.Errorf(\"status: %w\", err)\n\t}\n\td, err := time.ParseDuration(f[4])\n\tif err != nil {\n\t\treturn Entry{}, err\n\t}\n\treturn Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil\n}\n",
      "note": "**The only change in the file.** `split5` is asked first, and when it answers, its five fields are used as they are. When it declines, the old code runs, word for word, inside the `if`, so a line with tabs, or six fields, or an accented path gets exactly what it got before, error message included. `[5]string(all)` converts a slice of length 5 into an array of the same five strings."
    },
    {
      "code": "// Summary is what Count found.\ntype Summary struct {\n\tLines    int\n\tByStatus map[int]int\n\tByPath   map[string]int\n\tTotal    time.Duration\n}\n\n// Count reads every line from r. A line it cannot parse stops it, and the\n// error names the line.\nfunc Count(r io.Reader) (Summary, error) {\n\ts := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\tsc := bufio.NewScanner(r)\n\tfor n := 1; sc.Scan(); n++ {\n\t\te, err := Parse(sc.Text())\n\t\tif err != nil {\n\t\t\treturn s, fmt.Errorf(\"line %d: %w\", n, err)\n\t\t}\n\t\ts.Lines++\n\t\ts.ByStatus[e.Status]++\n\t\ts.ByPath[e.Path]++\n\t\ts.Total += e.Duration\n\t}\n\treturn s, sc.Err()\n}\n\n// PathCount is one row of Top.\ntype PathCount struct {\n\tPath string `json:\"path\"`\n\tHits int    `json:\"hits\"`\n}\n\n// Top returns the n paths with the most requests, the most first. Paths\n// with the same count come in alphabetical order.\nfunc Top(s Summary, n int) []PathCount {\n\trows := make([]PathCount, 0, len(s.ByPath))\n\tfor p, h := range s.ByPath {\n\t\trows = append(rows, PathCount{p, h})\n\t}\n\tslices.SortFunc(rows, func(a, b PathCount) int {\n\t\treturn cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))\n\t})\n\treturn rows[:min(n, len(rows))]\n}",
      "note": "`Summary`, `Count`, `PathCount` and `Top` are exactly as lesson 1 printed them."
    }
  ]
}
```


The design is the point. **`split5` never has to be right about a hard line, only about the lines it
accepts**, and it accepts only the ones where single spaces are the only white space, so
`strings.Fields` would have cut them in exactly the same places. Everything else, tabs, doubled
spaces, an accented path, a sixth field, goes down the path that has always handled it.

## Proving it agrees

That argument is convincing and could still be wrong, so it gets a test. The property to test is
not "`split5` returns these fields for this line" but the general one: **wherever it answers, it
answers what `strings.Fields` would**. `internal/tally/split_test.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/split_test.go",
  "parts": [
    {
      "code": "package tally\n\nimport (\n\t\"os\"\n\t\"slices\"\n\t\"strings\"\n\t\"testing\"\n)\n",
      "note": "**`package tally`, not `tally_test`**: `split5` is unexported, and only a test inside the package can call it."
    },
    {
      "code": "// agree fails the test if split5 answers for line and strings.Fields would\n// have answered differently. It reports whether split5 answered.\nfunc agree(t *testing.T, line string) bool {\n\tt.Helper()\n\tf, ok := split5(line)\n\tif !ok {\n\t\treturn false\n\t}\n\tif want := strings.Fields(line); !slices.Equal(f[:], want) {\n\t\tt.Errorf(\"split5(%q) = %q, strings.Fields says %q\", line, f, want)\n\t}\n\treturn true\n}\n",
      "note": "The property in one function: **wherever `split5` answers, it answers what `strings.Fields` would.** Declining is always allowed, because `Parse` then falls back to `strings.Fields` itself. `t.Helper` makes a failure point at the caller's line rather than this one."
    },
    {
      "code": "// Lines on which a careless split5 would disagree with strings.Fields.\nvar tricky = []string{\n\t\"\",\n\t\"GET / 200\",\n\t\"a b c d e f\",\n\t\" a b c d e\",\n\t\"a b c d e \",\n\t\"a  b c d e\",\n\t\"a\\tb c d e f\",\n\t\"a b c d e f\",\n\t\"a\\u0085b c d e f\",\n}\n",
      "note": "The lines a hand-written split gets wrong: too few or too many fields, spaces at an end or doubled, and three kinds of white space that are not the space character, `\\t`, the no-break space U+00A0 and U+0085."
    },
    {
      "code": "func TestSplit5(t *testing.T) {\n\tfor _, line := range tricky {\n\t\tagree(t, line)\n\t}\n\tdata, err := os.ReadFile(\"testdata/access.log\")\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tlines := strings.Split(strings.TrimSuffix(string(data), \"\\n\"), \"\\n\")\n\tfor _, line := range lines {\n\t\tif !agree(t, line) {\n\t\t\tt.Fatalf(\"split5 left a line genlog wrote to strings.Fields: %q\", line)\n\t\t}\n\t}\n}\n",
      "note": "Two checks. The tricky lines must not be answered wrongly, and **every one of the 100,000 lines `genlog` wrote must be answered**, because a `split5` that declined everything would be correct and useless."
    },
    {
      "code": "func FuzzSplit5(f *testing.F) {\n\tfor _, line := range tricky {\n\t\tf.Add(line)\n\t}\n\tf.Fuzz(func(t *testing.T, line string) {\n\t\tagree(t, line)\n\t})\n}",
      "note": "**A fuzz target states the same property for any string at all.** `go test` runs it on the seeds given to `f.Add` every time; `go test -fuzz` generates new inputs from them, for as long as it is allowed to, looking for one that fails."
    }
  ]
}
```


The tests lesson 5 wrote for `tally`, its `internal/tally/tally_test.go` with the bad lines and their
error messages, go into `~/prof` too: they check the other half of the promise, that `Parse` still
refuses what it refused before, with the same words. `go vet` first, then every test in the module,
lesson 1's `main_test.go` included:

```
ana@vm:~/prof$ go vet ./... && go test ./...
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	0.386s
?   	example.com/hits/tools/genlog	[no test files]
```

**A test that has never failed has not shown it can.** So Ana breaks `split5` on purpose, deleting the
two lines that decline any byte outside printable ASCII, which is the mistake a hand-written splitter
usually makes, and runs the package again:

```
ana@vm:~/prof$ cp internal/tally/split.go split.go.bak
ana@vm:~/prof$ sed -i "/c < .!. || c > .~./,+1d" internal/tally/split.go
ana@vm:~/prof$ go test ./internal/tally
--- FAIL: TestSplit5 (0.04s)
    split_test.go:39: split5("a\tb c d e f") = ["a\tb" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    split_test.go:39: split5("a\u00a0b c d e f") = ["a\u00a0b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    split_test.go:39: split5("a\u0085b c d e f") = ["a\u0085b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
--- FAIL: FuzzSplit5 (0.00s)
    --- FAIL: FuzzSplit5/seed#6 (0.00s)
        split_test.go:58: split5("a\tb c d e f") = ["a\tb" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    --- FAIL: FuzzSplit5/seed#7 (0.00s)
        split_test.go:58: split5("a\u00a0b c d e f") = ["a\u00a0b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    --- FAIL: FuzzSplit5/seed#8 (0.00s)
        split_test.go:58: split5("a\u0085b c d e f") = ["a\u0085b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
FAIL
FAIL	example.com/hits/internal/tally	0.390s
FAIL
ana@vm:~/prof$ mv split.go.bak internal/tally/split.go
```

Three of the tricky lines catch it, the tab and both Unicode spaces, once in `TestSplit5` and once as
seeds of the fuzz target, which `go test` runs as ordinary tests. Each failure prints the two answers
side by side, `["a\tb" "c" "d" "e" "f"]` against six fields, which is the whole bug in one line. The
`mv` puts the file back.

## Fuzzing for the lines nobody thought of

The tricky list holds the cases somebody thought of. `go test -fuzz` looks for the others: it starts
from the seeds, mutates them, keeps the inputs that reach new code, and runs the target on every one,
with one worker per processor, until the time is up or a failure turns up:

```
ana@vm:~/prof$ go test -fuzz FuzzSplit5 -fuzztime 10s ./internal/tally
fuzz: elapsed: 0s, gathering baseline coverage: 0/26 completed
fuzz: elapsed: 0s, gathering baseline coverage: 26/26 completed, now fuzzing with 4 workers
fuzz: elapsed: 3s, execs: 395640 (131840/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 6s, execs: 845178 (149859/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 9s, execs: 1264941 (139915/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 10s, execs: 1398846 (124132/sec), new interesting: 0 (total: 26)
PASS
ok  	example.com/hits/internal/tally	10.972s
```

**About 1.4 million generated strings in ten seconds, and none on which `split5` and `strings.Fields`
disagree.** "new interesting" counts inputs that took the code down a path no earlier input had
taken. The fuzzer keeps those in the go command's cache and starts from them next time, which is why
this run began from 26 inputs, the nine seeds and what earlier fuzzing on this machine had kept; a
first run begins from the nine. A failure would have
been written to `testdata/fuzz/FuzzSplit5/` inside the package, as a file `go test` then runs as a
seed for ever after, so a bug found once stays tested. Fuzzing is not proof, but together with the
argument above and the 100,000 lines of `genlog`, it is as much evidence as a change this size
deserves.
