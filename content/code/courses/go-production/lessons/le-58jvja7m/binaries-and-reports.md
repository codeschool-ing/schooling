---
title: Binaries, scan levels and reports for machines
version: 1
---

A source scan needs the source, the module graph and a Go to load them with. **What runs in
production is a binary**, built last month by a pipeline or downloaded from somebody's release page.
Once it and your checkout have drifted apart, "is this file on the server affected" is a different
question from "is my checkout affected". `govulncheck` can answer it from the binary alone, with
less precision, for reasons worth knowing before you trust either answer.

## What a binary remembers about itself

Every binary the go command builds carries a record of how it was built: the Go release, the main
module, and every dependency with its version and checksum. `go version -m` prints it:

```
ana@vm:~/langs$ go build -o accept-bin ./accept && go build -o tag-bin ./tag
ana@vm:~/langs$ go version -m accept-bin | head -n 4
accept-bin: go1.27.1
	path	example.com/langs/accept
	mod	example.com/langs	(devel)	
	dep	golang.org/x/text	v0.3.7	h1:olpwvP2KacW1ZWvsR7uQhoyTYvKAupfQrRGBFM352Gk=
```

**That record and the binary's symbol table are everything `-mode binary` reads.** The record gives
the module level: which modules at which versions, and which release of the standard library. The
symbol table, the list of function names the linker kept, stands in for the call graph. The linker
drops functions that nothing calls, so a vulnerable function that is still in the file is very
likely reachable:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Vulnerable symbols found:
      #1: language.ParseAcceptLanguage

Your code is affected by 1 vulnerability from 1 module.
This scan also found 0 vulnerabilities in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
3
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary tag-bin | tail -n 6; echo ${PIPESTATUS[0]}

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

The verdicts match section 03, and two things changed. **`Example traces found` became
`Vulnerable symbols found`**: the binary says the function is there and cannot say who calls it, so there is no
line of your code to go to. And the package count fell by one for each program. The binary records
that it was built with `GOOS=linux`, so the Windows-only `os` entry no longer applies to it, while
source, which could be built for any system, keeps it.

The weaknesses come from the same place. **A function can be linked in and still never run**, and
the documentation says so: a binary scan can report code that is in the file but unreachable. The
opposite failure is the one to watch for. Strip the symbol table, the way lesson 17 does to make a
binary smaller, and there is nothing left to look names up in:

```
ana@vm:~/langs$ go build -ldflags="-s -w" -o accept-small ./accept && stat -c "%s bytes  %n" accept-bin accept-small
2683796 bytes  accept-bin
1740960 bytes  accept-small
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-small | tail -n 4; echo ${PIPESTATUS[0]}
Your code is affected by 15 vulnerabilities from 1 module and the Go standard library.
This scan found no other vulnerabilities in packages you import or modules you
require.
Use '-show verbose' for more details.
3
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-small | grep -c '^Vulnerability #'
15
```

The same program went from 1 vulnerability to **15**. With no names to check, `govulncheck` falls
back to the module level and reports every vulnerable symbol of every module the record lists as
present. That includes twelve in the standard library's `net/http`, `crypto/tls` and
`html/template`, none of which `accept` imports. Nothing in this output says it guessed. **Scan the
binary before you strip it**, or scan the source the binary was built from, which is what section
05's CI job does.

## Choosing the level

`-scan` sets how far down the analysis goes: `symbol`, the default, `package` or `module`. **The
exit status follows the level you asked for**, so the same code can pass at one and fail at another.
Here is `tag` at the package level, and a copy of lesson 1's `hits`, which has no dependencies at
all, at the symbol and the module level:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -scan package ./tag | tail -n 5; echo ${PIPESTATUS[0]}

Your code may be affected by 2 vulnerabilities.
This scan also found 14 vulnerabilities in modules you require.
Use '-scan symbol' for more fine grained vulnerability detection and '-show
verbose' for more details.
3
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb ./... | tail -n 5; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb -scan module | tail -n 4; echo ${PIPESTATUS[0]}
    Fixed in: stdlib@go1.27.2

Your code may be affected by 13 vulnerabilities.
Use '-scan symbol' for more fine grained vulnerability detection.
3
```

The wording changes with the level: **"is affected" at the symbol level, "may be affected" above
it**, because above it nothing was traced. `hits` is clean at the symbol level and fails with 13 at
the module level, all of them the standard library of Go 1.27.1. The module level refuses a package
pattern and judges the module's requirements as a whole, which makes it the level most likely to
fail a build over code nobody calls. Keep the default for a gate.

## Reports for a program

The text is written for a person. `-format json` writes a stream of JSON objects, one after another,
for a program to read, and **with any `-format` other than `text` the exit status is 0 whatever was
found**:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -format json ./accept > scan.json; echo $?
0
ana@vm:~/langs$ jq -r 'keys[0]' scan.json | sort | uniq -c
      1 SBOM
      1 config
     24 finding
    191 osv
      2 progress
ana@vm:~/langs$ jq -c 'select(.finding.trace[0].function) | .finding | {osv, fixed_version, trace: [.trace[].function]}' scan.json
{"osv":"GO-2022-1059","fixed_version":"v0.3.8","trace":["ParseAcceptLanguage","preferred","main"]}
ana@vm:~/langs$ jq -c 'select(.config) | .config | {scan_level, scan_mode, go_version}' scan.json
{"scan_level":"symbol","scan_mode":"source","go_version":"go1.27.1"}
```

The stream holds the scan's settings, the modules it saw, every OSV entry that touches one of them,
191 here, and the findings. **A finding's trace runs from the vulnerable function up to your entry
point**, the reverse of `-show traces`, and how far down its first frame goes tells you the level: a
module and a version for a module-level finding, a package as well for a package-level one, and a
function with a position only for a symbol-level one. That is why the `jq` filter above, which keeps
findings whose first frame names a function, picked out exactly the one the text report put under
Symbol Results.

`-format sarif` writes SARIF, the format code-scanning services take in, with one result per
vulnerability and the level mapped to a severity:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -format sarif ./accept > scan.sarif; echo $?
0
ana@vm:~/langs$ jq -r '.runs[0].results[].level' scan.sarif | sort | uniq -c
      1 error
     14 note
      1 warning
ana@vm:~/langs$ jq '.runs[0].results[] | select(.level == "error") | .message.text' scan.sarif
"Your code calls vulnerable functions in 1 package (golang.org/x/text/language)."
```

`error` for the symbol level, `warning` for the package level, `note` for the module level: the same
1, 1 and 14 as the text summary. `-format openvex` exists as well, for VEX, a format for statements
about which vulnerabilities affect a product; it was not run here.

| run | exit status |
|---|---|
| text, and something found at the level asked for (`symbol` unless `-scan` says otherwise) | 3 |
| text, and nothing found at that level, whatever the coarser levels hold | 0 |
| `-format json`, `sarif` or `openvex`, whatever was found | 0 |
| a mistake on the command line, such as a pattern with `-scan module` | 2 |

**A job that writes JSON for a dashboard has to decide failure itself**, by reading the findings, or
run a second, text scan for its exit status. Forgetting that gives a pipeline that has never failed
and never will.
