---
title: Where the list comes from, and what it is checked against
version: 1
---

Every module your program depends on was written by somebody else, and some of them have bugs that a
stranger can use: a header that keeps a parser busy for a long time, an input that panics a server.
When one of those is found and fixed, it is written down. **`govulncheck` reads that written record
and asks one question of your code: does a known vulnerability actually reach this program?** It
answers with a list, a call path for each item, and an exit status a CI job can act on.

The common idea of a dependency scanner is a version check: read `go.mod`, compare each version
against a list, and flag every match. That is half of what `govulncheck` does. The other half is the
reason it exists. **A module at a vulnerable version is not the same as a program that runs the
vulnerable code**, and in every scan in this lesson the difference is most of the list.

## Installing it

`govulncheck` is a Go program, published in the module `golang.org/x/vuln`, and it installs the way
lesson 5 installed tools, into `~/go/bin`. This course pins v1.9.0:

```
ana@vm:~/langs$ go install golang.org/x/vuln/cmd/govulncheck@v1.9.0
ana@vm:~/langs$ govulncheck -version
Go: go1.27.1
Scanner: govulncheck@v1.9.0
DB: https://vuln.go.dev
```

`go install` printed nothing because this machine had already downloaded and built it; on yours it
prints a few `go: downloading` lines first. **The first line of `-version` is not the Go that built
`govulncheck`: it is the Go on your `PATH`**, the one whose standard library the scan will judge.
Section 05 uses that. The last line is the database it reads by default.

## The Go vulnerability database

The list lives at vuln.go.dev, and the Go security team keeps it. Each entry has an id of the form
`GO-2022-1059`, a year and a number, and lists the names the same problem has elsewhere: a CVE
number and a GitHub advisory, when they exist. Entries are written in OSV, the Open Source
Vulnerability format, which is JSON. Here is one, cut to the fields that matter here:

```
ana@vm:~/langs$ jq '{id, aliases, summary, affected}' ~/vulndb/ID/GO-2022-1059.json
{
  "id": "GO-2022-1059",
  "aliases": [
    "CVE-2022-32149",
    "GHSA-69ch-w2m2-3vjp"
  ],
  "summary": "Denial of service via crafted Accept-Language header in golang.org/x/text/language",
  "affected": [
    {
      "package": {
        "name": "golang.org/x/text",
        "ecosystem": "Go"
      },
      "ranges": [
        {
          "type": "SEMVER",
          "events": [
            {
              "introduced": "0"
            },
            {
              "fixed": "0.3.8"
            }
          ]
        }
      ],
      "ecosystem_specific": {
        "imports": [
          {
            "path": "golang.org/x/text/language",
            "symbols": [
              "MatchStrings",
              "ParseAcceptLanguage"
            ]
          }
        ]
      }
    }
  ]
}
```

Read it from the outside in, because **that order is the three levels `govulncheck` works at**:

| level | the field | what this entry says |
|---|---|---|
| module | `package.name` and `ranges` | `golang.org/x/text`, every version from the first (`"introduced": "0"`) up to but not including `0.3.8` |
| package | `imports[].path` | only the package `golang.org/x/text/language` has the bug |
| symbol | `imports[].symbols` | and only two of its functions, `MatchStrings` and `ParseAcceptLanguage` |

The `symbols` list is the part a person writes by reading the fix. It is what turns "you depend on a
bad version" into "your program calls the function that was fixed". It is also why an entry against
the standard library's `net/http` does not condemn every program built with that release of Go.

**This lab did not read vuln.go.dev**, because this machine cannot reach it. Every scan in this
lesson reads a copy of the same database in `~/vulndb`, handed to it with
`-db file:///home/ana/vulndb`. The copy was built from the entries the Go team publishes in their
repository, as it stood on 11 October 2026. On your machine you leave the flag out, and a plain
`govulncheck ./...` reads vuln.go.dev. Expect different counts from the ones printed here: the
database has had new entries since. What `govulncheck` sends to it, by its documentation, is the
paths of modules the database already lists, never your code or anything else about your program.

## Reachability

Knowing which functions are bad, `govulncheck` builds a call graph of your program: every function
that can call every other, starting from the program's entry points. For a `main` package those are
`main` and the `init` functions; for a library, every exported function and method. **A
vulnerability counts against your code only when some path of calls from an entry point arrives at a
function the entry names.** The two programs of section 03 import the same package of the same
module at the same version, and only one of them gets there:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two programs and the module golang.org/x/text at v0.3.7. accept.main calls accept.preferred, which calls language.ParseAcceptLanguage, one of the two functions GO-2022-1059 names; govulncheck reports that at the symbol level and exits with status 3. tag.main calls language.Parse in the same package, which the entry does not name, so the vulnerability is only at the package level and the exit status is 0. The packages secure/precis and unicode/norm carry GO-2026-6629 and GO-2026-5970, and neither program imports them: module level.\"><defs><marker id=\"vc-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"vc-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">your code</text><rect x=\"25\" y=\"50\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">accept.main</text><rect x=\"25\" y=\"116\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">accept.preferred</text><rect x=\"25\" y=\"232\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tag.main</text><path d=\"M110 84 V112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-amber)\"></path><text x=\"110\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">symbol level: reached,</text><text x=\"110\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">exit status 3</text><text x=\"110\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">package level: imported,</text><text x=\"110\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">never called, exit status 0</text><rect x=\"260\" y=\"20\" width=\"440\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">golang.org/x/text@v0.3.7</text><rect x=\"278\" y=\"56\" width=\"404\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">language</text><text x=\"668\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2022-1059</text><rect x=\"296\" y=\"96\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ParseAcceptLanguage</text><rect x=\"488\" y=\"96\" width=\"176\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"576\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MatchStrings</text><rect x=\"296\" y=\"156\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Parse</text><rect x=\"278\" y=\"226\" width=\"196\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"376.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">secure/precis</text><text x=\"376.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2026-6629</text><rect x=\"486\" y=\"226\" width=\"196\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"584.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">unicode/norm</text><text x=\"584.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2026-5970</text><text x=\"480\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">module level: required, never imported</text><path d=\"M195 133 C245 133 248 112 292 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-amber)\"></path><path d=\"M195 249 C248 249 250 172 292 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-phosphor)\"></path></svg>", "caption": "The same module, the same package, two programs. What decides the exit status is whether a path of calls from main reaches a function the entry names."}
```

Each finding lands at the most precise level it reaches. **The symbol level is the only one that
fails the run.** The other two are printed as context. They become findings the day somebody adds a
call, and a module you require is a dependency whether you call it or not.

The graph is built from source, so it has edges a reader would not expect and misses some a program
has. A call through an interface or a function value is followed conservatively, toward every
function it could reach, which can produce a path that never runs. A call made through `reflect` is
invisible, and so is anything reached through `unsafe`. Those are the documented limits, and they
point the same way: **a symbol finding deserves to be fixed rather than argued with**, and a clean
result means no known path, which is a strong statement and not a proof.
