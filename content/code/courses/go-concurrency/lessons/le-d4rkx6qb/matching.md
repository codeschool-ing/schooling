---
title: Finding, extracting and rewriting
version: 1
---

A regular expression is a small program for recognising text, and Go's `regexp` package compiles
one before it runs it. **`regexp.MustCompile` turns the pattern into a `*Regexp` once, and every
method after that runs the compiled machine**: find the first match, find all of them, pull out
the pieces in parentheses, replace. The program below does each to three lines of a web server's
log, saved as `match/main.go`:

```go
// Command match finds, extracts and rewrites with a regular expression.
package main

import (
	"fmt"
	"regexp"
)

const logs = `2026-10-16 09:12:03 GET /orders/1042 200 18ms
2026-10-16 09:12:04 POST /orders 201 95ms
2026-10-16 09:12:09 GET /orders/77 404 3ms`

var line = regexp.MustCompile(`(?m)^\S+ \S+ (?P<method>[A-Z]+) (?P<path>\S+) (?P<status>\d{3}) (?P<ms>\d+)ms$`)

func main() {
	fmt.Println(regexp.MustCompile(`\d{3}`).FindString("GET /orders/1042 200"))
	fmt.Println(regexp.MustCompile(`\b\d{3}\b`).FindString("GET /orders/1042 200"))
	fmt.Println(regexp.MustCompile(`/orders/\d+`).FindAllString(logs, -1))

	for _, m := range line.FindAllStringSubmatch(logs, -1) {
		fmt.Println(m[line.SubexpIndex("status")], m[line.SubexpIndex("path")])
	}

	ids := regexp.MustCompile(`/orders/(\d+)`)
	fmt.Println(ids.ReplaceAllString("GET /orders/1042", "/orders/{id=$1}"))

	_, err := regexp.Compile(`[a-z`)
	fmt.Println(err)
}
```

The patterns are written between backquotes, Go's raw strings, so that `\d` reaches the package as
a backslash and a `d` rather than as an escape the compiler would have to read first.

```
ana@vm:~/patterns$ go run ./match
104
200
[/orders/1042 /orders/77]
200 /orders/1042
201 /orders
404 /orders/77
GET /orders/{id=1042}
error parsing regexp: missing closing ]: `[a-z`
```

**The first line is a lesson on its own**: `\d{3}` asked for three digits and found `104`, the
start of `1042`, because a match is the leftmost one and nothing said where the digits had to end.
`\b`, a word boundary, says it, and the second line found `200`. A pattern that matches what you
wanted is not the same as a pattern that matches only that, and the difference shows on the input
you did not try.

`FindAllString` with `-1` returned every match. **`FindAllStringSubmatch` returned, for each line,
the whole match followed by each group**, and `SubexpIndex` turned the names written as
`(?P<status>…)` into positions, so the code reads `status` rather than `m[3]`. The `(?m)` at the
front made `^` and `$` match at the start and end of every line instead of the whole text.
`ReplaceAllString` wrote the first group back in as `$1`.

## `Compile` or `MustCompile`

`MustCompile` panics on a pattern that does not parse; `Compile` returns the error, and the last
line of the output is that error: `missing closing ]`. **A pattern written in the source is checked
once, when the program starts, so `MustCompile` in a package-level variable is the idiom**: a typo
stops the program on its first run rather than on the first request that reaches the bad line.
A pattern that comes from a user, a file or a flag is `Compile`, because a person's typo is an
error to report and not a reason to crash.
