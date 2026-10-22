---
title: Imported, or called
version: 1
---

The claim of section 02 is easiest to believe when two programs that differ in one call get two
different answers. **Both programs here import the same package of the same module at the same old
version, and only one of them calls the function the entry names.** They live in one module,
`example.com/langs`, in `~/langs`, and they depend on `golang.org/x/text` at v0.3.7, a release from
August 2021 that was current for over a year.

The first, `accept`, reads the value of an `Accept-Language` header, the line a browser sends to say
which languages its user reads and how much it prefers each. It prints one language per line with
its weight, most wanted first. A web server does exactly this to choose which translation of a page
to send, which is why the bug in GO-2022-1059 mattered: the header comes from whoever is on the
other end. Save it as `accept/main.go`:

```go
// Command accept prints the languages an Accept-Language header asks for,
// most wanted first.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: accept 'header value'")
		os.Exit(2)
	}
	langs, err := preferred(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "accept:", err)
		os.Exit(1)
	}
	for _, l := range langs {
		fmt.Println(l)
	}
}

// preferred reads a header and returns one line per language: the tag and
// its weight.
func preferred(header string) ([]string, error) {
	tags, weights, err := language.ParseAcceptLanguage(header)
	if err != nil {
		return nil, err
	}
	out := make([]string, len(tags))
	for i, t := range tags {
		out[i] = fmt.Sprintf("%s\t%.1f", t, weights[i])
	}
	return out, nil
}
```

The second, `tag`, checks one language tag, such as `EN-us`, and prints it in its canonical form
beside its base language. It uses `language.Parse`, from the same package, a function the entry does
not name. Save it as `tag/main.go`:

```go
// Command tag checks one language tag and prints its canonical form.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: tag LANGUAGE-TAG")
		os.Exit(2)
	}
	t, err := language.Parse(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "tag:", err)
		os.Exit(1)
	}
	base, _ := t.Base()
	fmt.Println(t, base)
}
```

Make the module, ask for the old version on purpose, and let `go mod tidy` settle `go.mod`. Then run
both, to see they work:

```
ana@vm:~/langs$ go mod init example.com/langs
go: creating new go.mod: module example.com/langs
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/langs$ go get golang.org/x/text@v0.3.7
go: added golang.org/x/text v0.3.7
ana@vm:~/langs$ go mod tidy && cat go.mod
module example.com/langs

go 1.27.1

require golang.org/x/text v0.3.7
ana@vm:~/langs$ go run ./accept "pt-BR,pt;q=0.9,en;q=0.5"
pt-BR	1.0
pt	0.9
en	0.5
ana@vm:~/langs$ go run ./tag EN-us
en-US en
```

**`go.mod` shows one requirement, and nothing in it says which functions the code uses.** A scanner
that only reads this file has to give both programs the same answer.

## The program that calls it

`govulncheck` takes package patterns the way `go build` and `go test` do. One pattern at a time,
starting with `accept`:

```
ana@vm:~/langs$ time govulncheck -db file:///home/ana/vulndb ./accept; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Example traces found:
      #1: accept/main.go:30:52: accept.preferred calls language.ParseAcceptLanguage

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.

real	0m2.448s
user	0m2.723s
sys	0m1.875s
3
```

Everything a defender needs is in the block under `Vulnerability #1`. **`Found in` is the version
you have, `Fixed in` the first version without the bug**, and the trace names the line of your own
code where the path leaves it: line 30, column 52 of `accept/main.go`, which is the call to
`language.ParseAcceptLanguage` inside `preferred`. The summary under it counts the other two levels,
which a default run does not list. The exit status is **3**, and that is what makes `govulncheck`
usable as a gate: any shell, `make` or CI step treats anything but 0 as a failure. The scan took a
little over two seconds.

The default trace is one step long. `-show traces` prints the whole path, from the entry point down
into the module:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show traces ./accept
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Example traces found:
      #1: for function golang.org/x/text/language.ParseAcceptLanguage
        main @ example.com/langs/accept/main.go:17:25
        preferred @ example.com/langs/accept/main.go:30:52
        ParseAcceptLanguage @ golang.org/x/text/language/parse.go:158:6
```

Read it from the top: `main` calls `preferred` at line 17, `preferred` calls the bad function at
line 30, and the function itself starts at line 158 of `parse.go` in the module. **In a real program
the path can be many calls deep and run through other modules.** The full trace is how you find out
which of your packages to change, or whether the call sits in a corner of the program that untrusted
input never reaches. The report says "example traces" because it shows one path per vulnerability,
not every path.

## The program that does not

The same scan on `tag`:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./tag; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 2 vulnerabilities in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

**Same module, same version, same package, and the exit status is 0.** The finding has not
disappeared; it has dropped a level. `-show verbose` lists what the summary only counts. Its output
is long, so here are its first 42 lines and then a count of its entries:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show verbose ./tag | head -n 42
Fetching vulnerabilities from the database...

Checking the code against the vulnerabilities...

The package pattern matched the following root package:
  example.com/langs/tag
Govulncheck scanned the following 2 modules and the go1.27.1 standard library:
  example.com/langs
  golang.org/x/text@v0.3.7

=== Symbol Results ===

No vulnerabilities found.

=== Package Results ===

Vulnerability #1: GO-2026-6604
    Root.Mkdir(All) can follow junctions out of the root on Windows in os
  More info: https://pkg.go.dev/vuln/GO-2026-6604
  Standard library
    Found in: os@go1.27.1
    Fixed in: os@go1.27.2
    Platforms: windows

Vulnerability #2: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8

=== Module Results ===

Vulnerability #1: GO-2026-6629
    Panic parsing crafted input in x/text/secure/precis in golang.org/x/text
  More info: https://pkg.go.dev/vuln/GO-2026-6629
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.41.0

Vulnerability #2: GO-2026-6617
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show verbose ./tag | grep -c '^Vulnerability #'
16
```

Sixteen entries in three groups, and each group answers a different question:

| group | here | what it means for `tag` |
|---|---|---|
| Symbol Results | none | no path from `main` reaches a function any entry names |
| Package Results | 2 | `tag` imports `language` and `os`, the packages these entries name, and calls none of the named functions |
| Module Results | 14 | `tag` requires the module, or uses that release of Go, and never imports the package |

GO-2022-1059 sits under Package Results because `language` is imported and `Parse` is not one of the
two names. **The `os` entry shows how a source scan treats platforms**: it is a Windows bug, marked
`Platforms: windows`, and a source scan lists it whatever machine you run it on, because source can
be built for any system. Of the 14 module entries, 12 are in the standard library of Go 1.27.1,
`net/http`, `crypto/tls`, `html/template` and others `tag` never imports, and two are in other
packages of `golang.org/x/text`; section 05 deals with both kinds.

What to do with a package-level finding is a judgement, and the report gives you what you need to
make it. `tag` is not affected today. **It is one edit from being affected**: whoever next calls
`ParseAcceptLanguage` in this module will see the next scan fail, and the cheapest fix, a version
bump, is the same now as then. Section 05 makes it.
