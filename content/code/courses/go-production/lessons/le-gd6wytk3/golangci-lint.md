---
title: "golangci-lint: one runner, one configuration"
version: 1
---

Sections 02 and 03 ran two linters, and a project that adopts both now has two installs to pin, two
configuration files in two formats, two output styles and two ideas of what an exit code means.
Add `errcheck` for dropped errors and a few more, and the CI step becomes a script of its own.
**`golangci-lint` is a runner: it carries more than a hundred linters inside one binary, runs the
ones a single YAML file names, and reports them in one format with one exit code.** Most of the
linters it carries are analyzers on the same framework as vet, so it loads and type-checks each
package once and hands the result to all of them, in parallel, and it caches what it found for
files that have not changed.

## Installing it, and what is inside

```
ana@vm:~/lint$ go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0 && golangci-lint version
golangci-lint has version 2.14.0 built with go1.27.1 from (unknown, modified: ?, mod sum: "h1:ot8QffRa4LzAAEgtvNYrVs9esxQ7xoTwoAv6uhp4ngA=") on (unknown)
ana@vm:~/lint$ du -b $(command -v staticcheck revive golangci-lint)
17189203	/home/ana/go/bin/staticcheck
15818634	/home/ana/go/bin/revive
71168128	/home/ana/go/bin/golangci-lint
ana@vm:~/lint$ golangci-lint linters --no-config | head -6
Enabled by your configuration linters:
errcheck: Errcheck is a program for checking for unchecked errors in Go code. These unchecked errors can be critical bugs in some cases.
govet: Vet examines Go source code and reports suspicious constructs. It is roughly the same as 'go vet' and uses its passes. [auto-fix]
ineffassign: Detects when assignments to existing variables are not used. [fast]
staticcheck: It's the set of rules from staticcheck. [auto-fix]
unused: Checks Go code for unused constants, variables, functions and types.
ana@vm:~/lint$ golangci-lint help linters | grep -c ": "
115
ana@vm:~/lint$ go version -m $(command -v golangci-lint) | grep -E "honnef|revive"
	dep	github.com/mgechev/revive	v1.17.0	h1:hwTTVC3svSv9X2FA2hiYT17Uws+lfxDWhPxzBZZCREg=
	dep	honnef.co/go/tools	v0.8.1	h1:+JKf3xJ1ni4CwrhVg4/pqsfPGP6vNAXcKbMXJodYx3w=
```

The binary is **71,168,128 bytes**, four times the size of staticcheck's, because the other linters
are compiled into it. `golangci-lint help linters` lists 115 of them. With no configuration file,
the set called `standard` runs, and it is the five that `linters` printed: `errcheck` for dropped
errors, `govet`, `ineffassign` for assignments nothing reads, `staticcheck` and `unused`.

The last command shows something worth knowing before a version is pinned. **The staticcheck and
revive inside golangci-lint 2.14.0 are v0.8.1 and v1.17.0**, one release behind the v0.8.2 and v1.17.1
installed on their own in sections 02 and 03. Those versions are golangci-lint's choice, made in its
own `go.mod`, and each of its releases moves some of them; its changelog for 2.14.0 lists eleven
linters updated, revive from 1.15.0 to 1.17.0 among them.

## The defaults, on `~/lint`

`~/lint` is as section 03 left it, `report.go` included and its revive directive taken out. `--no-config`
makes sure no file is read, and `--output.text.print-issued-lines=false` prints one line per
finding instead of three:

```
ana@vm:~/lint$ golangci-lint run --no-config --output.text.print-issued-lines=false; echo $?
internal/tally/report.go:48:14: Error return value of `os.WriteFile` is not checked (errcheck)
main.go:33:13: Error return value of `fmt.Fprint` is not checked (errcheck)
main.go:42:13: Error return value of `fmt.Fprint` is not checked (errcheck)
main.go:45:13: Error return value of `fmt.Fprintf` is not checked (errcheck)
main.go:64:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
main.go:66:14: Error return value of `fmt.Fprintf` is not checked (errcheck)
main.go:88:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
main.go:108:16: Error return value of `f.Close` is not checked (errcheck)
tools/genlog/main.go:27:15: Error return value of `w.Flush` is not checked (errcheck)
tools/genlog/main.go:32:14: Error return value of `fmt.Fprintf` is not checked (errcheck)
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
internal/tally/report.go:6:2: SA1019: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details. (staticcheck)
internal/tally/report.go:23:6: S1003: should use strings.Contains(path, "/api/") instead (staticcheck)
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:63:6: func percent is unused (unused)
16 issues:
* errcheck: 10
* govet: 1
* staticcheck: 4
* unused: 1
1
```

**Sixteen findings, and ten of them are `errcheck`.** That is what a first run over an existing
project looks like, and it is worth reading the ten before deciding what they mean:

| where | what was dropped | worth fixing? |
|---|---|---|
| `report.go:48` | the error from `os.WriteFile` | yes: `Save` reports success for a file it never wrote |
| `genlog/main.go:27` | the error from `w.Flush`, in a `defer` | yes, arguably: a full disk truncates the log and `genlog` exits 0 |
| `main.go:108` | the error from closing a file opened for reading | no: there is nothing a reader could have lost |
| seven `fmt.Fprint` lines | the error from writing a message to standard error | no: if standard error cannot be written to, there is nobody to tell |

One real bug, one judgement call and eight lines of noise. **golangci-lint 2 reports every one of
them, on purpose**: version 1 hid the printing and closing cases by default, and the changelog of
2.0.0 lists "No exclusions by default", which leaves the choice to each project. The two lines from `govet` and
`staticcheck` on `report.go` show two smaller things. `govet` here runs one analyzer that `go vet`
does not, `inline`, which reports calls to functions marked `//go:fix inline`, and in Go 1.27.1
`ioutil.ReadFile` is one of them; it is the analyzer `go fix` uses to rewrite such calls. And there
is one `ST1005` line where staticcheck alone printed two, because by default golangci-lint keeps one
finding per line.

Put side by side, the four tools' defaults found these:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 366\" role=\"img\" aria-label=\"The nine problems in report.go, one a row, against four tools run with their defaults. go vet finds none of them. staticcheck finds five: the deprecated package as SA1019, strings.Index as S1003, the uint test as SA4003, the error string as ST1005 and the unused function as U1000. revive finds four: the error string, the context passed second, the missing doc comment and the private return type. golangci-lint's standard set finds six: staticcheck's five, the deprecated call also through govet's inline, and the dropped error of os.WriteFile through errcheck. No tool finds all nine.\"><text x=\"302.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">go vet</text><text x=\"388.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">staticcheck</text><text x=\"520.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">revive</text><text x=\"658.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">golangci-lint</text><text x=\"16\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a deprecated package imported</text><rect x=\"270\" y=\"50\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"50\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA1019</text><rect x=\"442\" y=\"50\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"50\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA1019, inline</text><text x=\"16\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">strings.Index compared with -1</text><rect x=\"270\" y=\"80\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"80\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S1003</text><rect x=\"442\" y=\"80\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"80\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S1003</text><text x=\"16\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a uint tested with &gt;= 0</text><rect x=\"270\" y=\"110\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"110\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA4003</text><rect x=\"442\" y=\"110\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"110\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA4003</text><text x=\"16\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">error string: capital, full stop</text><rect x=\"270\" y=\"140\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"140\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ST1005</text><rect x=\"442\" y=\"140\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">error-strings</text><rect x=\"606\" y=\"140\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ST1005</text><text x=\"16\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a function nothing calls</text><rect x=\"270\" y=\"170\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"170\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U1000</text><rect x=\"442\" y=\"170\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"170\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">unused</text><text x=\"16\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">context not the first parameter</text><rect x=\"270\" y=\"200\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"200\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"200\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">context-as-argument</text><rect x=\"606\" y=\"200\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">exported, with no doc comment</text><rect x=\"270\" y=\"230\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"230\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"230\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exported</text><rect x=\"606\" y=\"230\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">exported, returns a private type</text><rect x=\"270\" y=\"260\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"260\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"260\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">unexported-return</text><rect x=\"606\" y=\"260\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"302\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the error of os.WriteFile dropped</text><rect x=\"270\" y=\"290\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"290\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"290\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"290\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">errcheck</text><line x1=\"16\" y1=\"326\" x2=\"710\" y2=\"326\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"16\" y=\"344\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">rows found</text><text x=\"302.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">0</text><text x=\"388.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"520.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"658.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">6</text></svg>", "caption": "The nine problems of report.go against four tools, each with its defaults. Vet finds none, and no one tool finds all nine: the three rows only revive finds are missing from golangci-lint's standard set, and the configuration below adds them."}
```

## A configuration file

`.golangci.yml` at the top of the module is found on its own; `golangci-lint` looks for it in the
current directory and the directories above. This one keeps the standard set, adds the three revive
rules nothing else has plus `error-strings`, and silences the errors every program drops. Save it as
`.golangci.yml`:

```schooling-example
{
  "language": "yaml",
  "file": ".golangci.yml",
  "parts": [
    {
      "code": "# .golangci.yml: what golangci-lint runs over this module, and what it keeps quiet.\nversion: \"2\"\n",
      "note": "**`version: \"2\"` is compulsory.** golangci-lint 2 refuses a file without it, with `unsupported version of the configuration` and exit status 3, and `golangci-lint migrate` rewrites a version 1 file into this format."
    },
    {
      "code": "linters:\n  default: standard\n  enable:\n    - revive\n    - nolintlint",
      "note": "`default` picks the starting set: `standard` is the five of `golangci-lint linters`, and `all`, `none` and `fast` are the others. `enable` adds to it, here revive and a linter that checks the `//nolint` comments themselves."
    },
    {
      "code": "  settings:\n    revive:\n      rules:\n        - name: context-as-argument\n        - name: error-strings\n        - name: exported\n        - name: unexported-return\n    nolintlint:\n      require-explanation: true\n      require-specific: true",
      "note": "Each linter's own settings live under its name. revive's rules are the ones from its TOML, written in YAML, and **listing any switches off revive's defaults here as well**, so the four this module wants are named. `nolintlint` will demand a linter name and a reason in every `//nolint`."
    },
    {
      "code": "  exclusions:\n    presets:\n      - std-error-handling\n",
      "note": "**A preset is a named set of exclusions.** `std-error-handling` stops `errcheck` reporting the errors almost every program drops on purpose: printing, closing, flushing, `os.Remove`, setting an environment variable."
    },
    {
      "code": "formatters:\n  enable:\n    - gofmt\n    - goimports\n  settings:\n    goimports:\n      local-prefixes:\n        - example.com/hits\n",
      "note": "Lesson 6's two formatters, run by the same binary. `local-prefixes` is `goimports -local`, written once. `golangci-lint run` reports a file that is not formatted, and `golangci-lint fmt` rewrites it."
    },
    {
      "code": "issues:\n  max-issues-per-linter: 0\n  max-same-issues: 0\n  uniq-by-line: false",
      "note": "By default the output stops at 50 findings per linter and 3 with the same text, and keeps one finding per line. **Zero lifts the two caps**, and `uniq-by-line: false` shows two findings that land on the same line."
    }
  ]
}
```

`golangci-lint config verify` checks a file against the schema built into the binary. **That
matters because `run` ignores a key it does not know**: a file saying `enabel:` where it meant
`enable:` runs the standard set, reports on it and exits 0, with revive never started. The schema
does not let it through:

```
ana@vm:~/lint$ printf 'version: "2"\nlinters:\n  enabel: [revive]\n' > typo.yml
ana@vm:~/lint$ golangci-lint config verify -c typo.yml; echo $?
jsonschema: "linters" does not validate with "/properties/linters/additionalProperties": additional properties 'enabel' not allowed
The command is terminated due to an error: the configuration contains invalid elements
3
```

So the check is worth running before the real file is used, and in CI before the linters:

```
ana@vm:~/lint$ golangci-lint config verify && golangci-lint run --output.text.print-issued-lines=false; echo $?
internal/tally/report.go:48:14: Error return value of `os.WriteFile` is not checked (errcheck)
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
internal/tally/report.go:15:1: exported: exported function NewReport should have comment or be unexported (revive)
internal/tally/report.go:15:27: unexported-return: exported func NewReport returns unexported type *tally.report, which can be annoying to use (revive)
internal/tally/report.go:40:24: context-as-argument: context.Context should be the first parameter of a function (revive)
internal/tally/report.go:45:21: error-strings: error strings should not be capitalized or end with punctuation or a newline (revive)
internal/tally/report.go:6:2: SA1019: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details. (staticcheck)
internal/tally/report.go:23:6: S1003: should use strings.Contains(path, "/api/") instead (staticcheck)
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
internal/tally/report.go:63:6: func percent is unused (unused)
12 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 5
* unused: 1
1
```

**Twelve findings, all of them in `report.go`.** The preset took away the nine `errcheck` lines in
`main.go` and `genlog`, including the arguable `w.Flush`: a preset is a trade, and this one is made
knowing that. revive added its four, and with `uniq-by-line: false` both of staticcheck's `ST1005`
messages are back, beside revive's `error-strings` on the same line. **Every finding on this list is
one a reviewer would want fixed**, which is what the configuration is for.

## `//nolint`, and the linter that checks it

golangci-lint's directive is `//nolint:LINTER // reason`, at the end of the line it excuses or on
the line above a declaration, where it covers the whole declaration. A bare `//nolint` silences every
linter on that line, and it is the easiest thing in the world to type when a build is red. Here is
one, typed on the line with the real bug:

```
ana@vm:~/lint$ sed -i 's|0o644)$|& //nolint|' internal/tally/report.go
ana@vm:~/lint$ golangci-lint run ./internal/... | head -6
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
	data, err := ioutil.ReadFile(path)
	             ^
internal/tally/report.go:48:42: directive `//nolint` should mention specific linter such as `//nolint:my-linter` (nolintlint)
	os.WriteFile(path, []byte(text), 0o644) //nolint
	                                        ^
ana@vm:~/lint$ sed -i 's| //nolint$||; s|^func percent.*{$|& //nolint:unused // kept for the -percent flag of the next release|' internal/tally/report.go
ana@vm:~/lint$ golangci-lint run --output.text.print-issued-lines=false | tail -8
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
11 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 5
```

**The `errcheck` finding on line 48 disappeared, and `nolintlint` reported the directive
instead.** Without `nolintlint` the bare `//nolint` would have hidden the one finding in this module
that loses data, and nothing would have said so. With `require-specific` and `require-explanation`,
the only directive that passes is one that names the linter and says why, like the second, on the
function nobody calls yet. `percent` left the list, and eleven findings remain.

A directive is right for one line with a reason that belongs beside the code. **A pattern that recurs
belongs in `exclusions.rules`** in the YAML, matched by path, linter or message text, where it can be
reviewed as one decision instead of found as thirty comments.
