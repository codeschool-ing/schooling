---
title: Choosing a module before you depend on it
version: 1
---

The usual way to pick a dependency is to search, take the first result that compiles, and move
on. It feels safe because the choice can be undone with one `go get …@none`. It is undone less
often than that suggests: **every module you add is code that runs inside your program, with
everything your program is allowed to do**, and three years later it is still there, at whatever
version you last asked for. The decision deserves the five minutes this section spends on it.

Lesson 8 left a question open. A user sees one character where Go sees two runes, and the standard
library stops at runes, so counting what a reader calls characters needs a module from outside.
Two candidates come up for it, and the rest of the section is the comparison, run in the lab.

## pkg.go.dev, the first page to read

**pkg.go.dev** is where lesson 4 sent you for the documentation of any public module, and the top
of a package's page answers half of the questions before you read any code. On the day the lab
ran, the two pages said:

| | `github.com/rivo/uniseg` | `github.com/clipperhouse/uax29/v2/graphemes` |
|---|---|---|
| version | v0.4.7 | v2.7.0 |
| published | 8 February 2024 | 16 February 2026 |
| licence | MIT | MIT |
| imported by | 546 | 10 |

"Imported by" is the number of packages pkg.go.dev knows of that import this one, and on that
number alone the first candidate wins easily. **Popularity measures the past**, though: it counts
the programs that chose a module, not whether the module still deserves the choice. The rest of
the evidence is in the modules themselves, and the go command fetches it without a browser.

## Five questions, answered in the terminal

`go list -m` prints any field of a module's information with `-f`, including the time its version
was published:

```
ana@vm:~/thirdparty-width$ go list -m -f "{{.Path}} {{.Version}} {{.Time}}" github.com/rivo/uniseg@latest github.com/clipperhouse/uax29/v2@latest
github.com/rivo/uniseg v0.4.7 2024-02-08 13:16:15 +0000 UTC
github.com/clipperhouse/uax29/v2 v2.7.0 2026-02-16 15:57:44 +0000 UTC
```

A module's last release being old is not a verdict on its own; a small, finished library may have
nothing left to change. What makes it a verdict here is the subject. Characters are defined by
Unicode, which keeps publishing new editions with new characters, and lesson 8 showed this Go's `unicode` package
at 17.0.0. Each module's source says which edition its tables come from, along with its licence
and its own requirements:

```
ana@vm:~/thirdparty-width$ cd $(go env GOMODCACHE)/github.com/rivo/uniseg@v0.4.7 && head -1 LICENSE.txt && grep -n "Unicode version" graphemerules.go && cat go.mod
MIT License
40:// Unicode version 15.0.0.
module github.com/rivo/uniseg

go 1.18
ana@vm:~/thirdparty-width$ cd $(go env GOMODCACHE)/github.com/clipperhouse/uax29/v2@v2.7.0 && head -1 LICENSE && grep -n "Public/" graphemes/trie.go && cat go.mod
MIT License
4:// from https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakProperty.txt
module github.com/clipperhouse/uax29/v2

go 1.18

// Surprising allocations in this release, do not use.
retract v2.1.0

// This release was effectively identical to v2.0.1, and
// only exists to revert the regression introduced in v2.1.0.
retract v2.1.1
```

`uniseg` was built from Unicode 15.0.0 and `uax29` from 17.0.0. Section 02 saw what out-of-date
tables look like on the screen: the old `go-runewidth` gave a recent emoji one column, and the new
one gave it two. Neither `go.mod` has a `require` line, so neither brings any other module with it. And the second one
carries two `retract` lines, which section 05 explains: its author withdrew two bad releases, with
a sentence saying why, which is what a maintained module looks like.

There is one more witness. Section 02's `go-runewidth` is imported by 3,302 packages on pkg.go.dev,
and its author faced the same choice. The proxy keeps every version's `go.mod`, so the moment of the
decision can be read:

```
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.17.mod
module github.com/mattn/go-runewidth

go 1.9

require github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.18.mod
module github.com/mattn/go-runewidth

go 1.20

require github.com/clipperhouse/uax29/v2 v2.2.0
```

So one of the ten importers of `uax29/v2/graphemes` is a module thousands of packages depend on,
which is also a lesson about "imported by": it counts direct importers only. On this evidence the
second candidate is the better bet for new code today. **Keep the questions,
not the verdict**, because the verdict changes the day either module makes a release:

| question | where the answer is |
|---|---|
| may I use it? | the licence: the `LICENSE` file, and pkg.go.dev's licence line |
| is it maintained? | the date of the last release, and whether it keeps up with what it depends on |
| what does it bring with it? | its `go.mod`, and `go list -m all` after a `go get` |
| who else trusts it? | "imported by" on pkg.go.dev, and which well-known modules require it |
| does it have known vulnerabilities? | `govulncheck`, below |

A licence decides whether you may ship the module at all. MIT, BSD and Apache 2.0 let you use the
code in nearly any program, including one you sell; some others place conditions on the program
that includes them. pkg.go.dev marks "Redistributable license" in its details when it recognises
the licence as one that allows redistribution. If the licence is unfamiliar, ask before you `go get`, not after you
ship.

## How much it brings

Both candidates arrive alone. A web framework is the other end of the scale, and one `go get` of
a popular one, in an empty module, shows it:

```
ana@vm:~/thirdparty-gin$ go get github.com/gin-gonic/gin@v1.12.0 2>&1 | grep -c "^go: added"
30
ana@vm:~/thirdparty-gin$ go list -m all | wc -l
56
ana@vm:~/thirdparty-gin$ go list -m all | grep golang.org/x/
golang.org/x/arch v0.22.0
golang.org/x/crypto v0.48.0
golang.org/x/mod v0.32.0
golang.org/x/net v0.51.0
golang.org/x/sync v0.19.0
golang.org/x/sys v0.41.0
golang.org/x/term v0.40.0
golang.org/x/text v0.34.0
golang.org/x/tools v0.41.0
```

One command added 30 requirements to `go.mod`, and the build graph holds 55 modules besides your
own. Most of them are good code from careful people, and that is not the point. **Each one is
code you ship, a licence you accepted and one more place a vulnerability can appear.** A framework
may well be worth it; for one route, the standard library's `net/http` is worth looking at first.

## govulncheck: known flaws in what you call

The last question has a tool of its own. **`govulncheck`**, from the module `golang.org/x/vuln`,
compares your module's dependencies, and the standard library of the Go that builds it, with the
Go vulnerability database, and reports the known vulnerabilities your code can reach. You install
it like any command, with `go install golang.org/x/vuln/cmd/govulncheck@latest`; the lab has
v1.8.0. By default it reads the database at vuln.go.dev, which the lab cannot reach, so every scan
below names a copy of the same database, built from its source of 5 October 2026, with
`-db file:///home/ana/thirdparty-vulndb`. On your machine, leave that flag out.

To have something to find, this module asks on purpose for a version of `golang.org/x/text` from
2021:

```go
// Command locale reads a language tag such as pt-BR.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	tag, err := language.Parse(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	base, _ := tag.Base()
	region, _ := tag.Region()
	fmt.Println(tag, base, region)
}
```

```
ana@vm:~/thirdparty-locale$ go get golang.org/x/text@v0.3.6
go: added golang.org/x/text v0.3.6
ana@vm:~/thirdparty-locale$ go run . pt-BR
pt-BR pt BR
```

The program works, which is exactly why nobody would notice. Then the scan:

```
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2021-0113
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.3.7
    Example traces found:
      #1: main.go:12:28: locale.main calls language.Parse

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 1 vulnerability
in modules you require, but your code doesn't appear to call these
vulnerabilities.
Use '-show verbose' for more details.
3
```

Read the report as three facts. The vulnerability has an identifier, `GO-2021-0113`, and a page of
its own. It is in `golang.org/x/text` at the version you have, and it is fixed from v0.3.7 on. And
**your code reaches it**: line 12 of `main.go` calls `language.Parse`, which is the affected
function. That trace is what separates govulncheck from a plain list of advisories. It follows
the calls, so a flaw in a function your program never calls is reported separately and does not
change the exit status, which is 3 when your code is affected and 0 when it is not.

`-show verbose` prints what the short report summarised, starting with what was scanned:

```
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | head -9
Fetching vulnerabilities from the database...

Checking the code against the vulnerabilities...

The package pattern matched the following root package:
  example.com/locale
Govulncheck scanned the following 2 modules and the go1.27.1 standard library:
  example.com/locale
  golang.org/x/text@v0.3.6
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | sed -n "/Package Results/,\$p"
=== Package Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.3.8

=== Module Results ===

Vulnerability #1: GO-2026-5970
    Infinite loop on invalid input in golang.org/x/text
  More info: https://pkg.go.dev/vuln/GO-2026-5970
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.39.0

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 1 vulnerability
in modules you require, but your code doesn't appear to call these
vulnerabilities.
```

The package result is in `language`, the package you import, in functions this program does not
call; the module result is in another package of the same module, which you do not import at all.
Neither can be reached today, and both can be the day somebody adds a line. That is why the fix is
not the version the first report named. v0.3.7 would end the first finding and keep the other two,
and the three "Fixed in" lines between them point past v0.39.0. **Upgrade to the newest release
and scan again**:

```
ana@vm:~/thirdparty-locale$ go get golang.org/x/text@latest
go: upgraded golang.org/x/text v0.3.6 => v0.42.0
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?
No vulnerabilities found.
0
ana@vm:~/thirdparty-locale$ go run . pt-BR
pt-BR pt BR
```

"No vulnerabilities found" means that nothing in the database matches what your code calls, at
the versions it uses, on the day you asked. The database keeps growing and your `go.mod` does not
move by itself, so **a scan is a reading, not a certificate**: run it again before each
release, and whenever a dependency changes.
