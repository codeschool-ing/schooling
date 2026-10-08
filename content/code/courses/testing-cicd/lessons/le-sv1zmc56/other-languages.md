---
title: The same measurement in other languages
version: 2
---

Every mainstream language has a coverage tool, and they all measure the same thing in the same
way: instrument the code, run the tests, count what ran. What differs is the unit they count and
the name of the command.

| language | tool | counts |
|---|---|---|
| Python | `coverage.py` | lines and, when asked, branches |
| JavaScript and TypeScript | Istanbul (`nyc`), `c8`, built into Jest and Vitest | statements, branches, functions, lines |
| Java and Kotlin | JaCoCo | instructions, branches, lines |
| Go | `go test -cover` | statements |
| C# | Coverlet | lines, branches |

## Go, on this repository

The Go side of the repository that publishes this course has coverage built into its test command.
Two of its libraries, the grader every exam answer goes through and the parser of per-track
passages, measured from a checkout. You do not need to type this one: the repository is public and
a clone with Go 1.25 would print the same, but nothing later in the course uses it, and the numbers
are the point:

```
ana@laptop:~/schooling$ go test -count=1 -cover ./internal/grade/ ./internal/trackblock/
ok  	github.com/codeschool-ing/schooling/internal/grade	0.017s	coverage: 81.4% of statements
ok  	github.com/codeschool-ing/schooling/internal/trackblock	0.003s	coverage: 96.6% of statements
ana@laptop:~/schooling$ go test -coverprofile=/tmp/grade.out ./internal/grade/ > /dev/null; go tool cover -func=/tmp/grade.out | sort -k3 -n | head -4
github.com/codeschool-ing/schooling/internal/grade/expr.go:309:		unary			30.0%
github.com/codeschool-ing/schooling/internal/grade/expr.go:361:		number			47.1%
github.com/codeschool-ing/schooling/internal/grade/numeric.go:90:	key			50.0%
github.com/codeschool-ing/schooling/internal/grade/grade.go:145:	CheckKey		66.7%
```

The first command prints one percentage per package: **81.4%** of the grader's statements and
**96.6%** of the parser's. `-count=1` makes Go run the tests rather than reuse a cached result,
which it does by default when nothing changed. The second writes a profile and lists coverage per
function, sorted so the least covered come first: `unary` in `expr.go` at **30.0%**, then `number`
at **47.1%**.

Those two functions are parts of the expression parser behind the `expression-answer` question
type, and the low numbers are a lead, not a verdict. They say that most of `unary`'s statements, the
handling of signs in front of an expression, never ran in this package's tests. Whether that matters is the same
question as in Python: what would a wrong answer there cost? A student whose correct `-x + 1` is
marked wrong is a real failure, so the profile points at a test worth adding, and lesson 4's other
tools, a mutant or an edge, say which one.

## What carries across

Everything in this lesson is independent of the tool:

- coverage says what **ran**, never what was **checked** (section 04);
- branches catch what lines miss, and both miss what happens inside one line (section 03);
- a number made into a target gets met by tests that check nothing (section 06);
- the useful gate is on the lines a change added, and the useful reading is the list of what is
  missing (sections 07 and 09).

Go's `statements` and Python's `lines` differ in detail, and nobody should compare a percentage
from one tool with a percentage from another. **Compare a project with itself over time**, and read
the missing list, in whichever language it is written.
