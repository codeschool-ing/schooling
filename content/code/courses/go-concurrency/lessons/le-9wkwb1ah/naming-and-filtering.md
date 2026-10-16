---
title: Names that find their case
version: 1
---

A row's `name` is the only part of the table the report prints, so it is what somebody reads at
the moment a case fails. **Name a case after what makes it different**, the way the rows above
are named: `accents`, `digits`, `only punctuation`. A name like `case 3` or `test2` says nothing
in a failure and stops saying anything the day a row is inserted above it, because the numbers
move and the rows do not.

## What the report does with a name

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
=== RUN   TestCount/empty
=== RUN   TestCount/only_punctuation
=== RUN   TestCount/digits
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- PASS: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
    --- PASS: TestCount/digits (0.00s)
=== RUN   TestCountFile
--- PASS: TestCountFile (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

**The space in `only punctuation` became an underscore**, so the full name is one word that a
shell and a regular expression can carry without quoting trouble. Seven rows, seven subtests, in
the order of the table.

## Running one row

`-run` works on these names exactly as it did on lesson 25's subtests. The pattern may be written
with the space or with the underscore, because the testing package rewrites the pattern the same
way it rewrote the name:

```
ana@vm:~/wordcount$ go test -v -run 'TestCount/only punctuation'
=== RUN   TestCount
=== RUN   TestCount/only_punctuation
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
=== RUN   TestCountFile
--- PASS: TestCountFile (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

One row of `TestCount` ran, and so did the whole of `TestCountFile`, which nobody asked for. **The
first level of the pattern, `TestCount`, is a regular expression that also matches inside
`TestCountFile`**, and that test has no subtests for the second level to filter. Anchoring the
first level makes the command mean what it says:

```
ana@vm:~/wordcount$ go test -v -run '^TestCount$/only_punctuation'
=== RUN   TestCount
=== RUN   TestCount/only_punctuation
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
PASS
ok  	example.com/wordcount	0.002s
```

The habit is worth keeping for any name that is the beginning of another name. A test suite grows
by adding `TestCountFile` beside `TestCount`, and a pattern that matched one test yesterday quietly
matches two today.

## Skipping a row on purpose

Sometimes a case is known to fail and is being worked on, or needs something the machine may not
have. **`t.Skip` ends a test as skipped rather than failed, with a reason that `-v` prints.** It is
the honest alternative to commenting a row out, because a skipped case still appears in the report
every time the suite runs, and a commented-out one disappears from everybody's view. Use it with a
reason somebody can act on, and remove it when the reason is gone.
