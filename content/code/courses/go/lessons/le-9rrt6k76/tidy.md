---
title: A dependency, go mod tidy and go.sum
version: 1
---

Lesson 8 left a problem open: `café` can be typed with a precomposed `é`, or as `cafe` followed by a
combining accent, and the two strings are not equal. The standard library has no function that fixes
it. The package that does, `golang.org/x/text/unicode/norm`, is maintained by the Go project in a
module of its own, outside the standard library. Here is the program that uses it, in
`~/mods-accents`:

```go
// Command accents compares two spellings of one word.
package main

import (
	"fmt"

	"golang.org/x/text/unicode/norm"
)

func main() {
	typed := "cafe\u0301" // e, then a combining accent
	stored := "caf\u00e9" // one precomposed letter
	fmt.Printf("%+q is %d bytes\n", typed, len(typed))
	fmt.Printf("%+q is %d bytes\n", stored, len(stored))
	fmt.Println("equal as typed:  ", typed == stored)
	fmt.Println("equal after NFC: ", norm.NFC.String(typed) == stored)
}
```

The import is written exactly like `"fmt"`, only longer. The blank line between the two is a
convention, the standard library first and everything else after it. A language with a package
manager usually has you declare a dependency in a manifest first and import it second. **In Go the
import line is the declaration.** Nothing else in the module mentions the dependency yet, and the go
command says so:

```
ana@vm:~/mods-accents$ go run .; echo $?
main.go:7:2: no required module provides package golang.org/x/text/unicode/norm; to add it:
	go get golang.org/x/text/unicode/norm
1
```

The suggested `go get` works, and lesson 40 uses it to choose versions. The command that reads every
import of the module at once and fixes `go.mod` to match is `go mod tidy`.

## tidy, on a machine that never saw the module

The lab's module cache already held `golang.org/x/text`, because other lessons had used it. To see
what a first download prints, the command below points `GOMODCACHE`, the variable lesson 3 listed,
at an empty directory for this one run:

```
ana@vm:~/mods-accents$ GOMODCACHE=~/mods-cache go mod tidy
go: finding module for package golang.org/x/text/unicode/norm
go: downloading golang.org/x/text v0.42.0
go: found golang.org/x/text/unicode/norm in golang.org/x/text v0.42.0
ana@vm:~/mods-accents$ cat go.mod
module example.com/accents

go 1.27.1

require golang.org/x/text v0.42.0
ana@vm:~/mods-accents$ cat go.sum
golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=
ana@vm:~/mods-accents$ go run .
"cafe\u0301" is 6 bytes
"caf\u00e9" is 5 bytes
equal as typed:   false
equal after NFC:  true
```

The three `go:` lines are the work in order. The import path named a package, not a module, so the
go command asked the proxy which module provides it, took the latest version, downloaded it, and
wrote the answer into `go.mod` as a `require` line. NFC is the Unicode form that composes an `e` and
its accent into one letter, so after `norm.NFC.String` the six bytes became the stored five and the
comparison came out true. `%+q` printed both strings with every non-ASCII character escaped, which
is how you can tell them apart on the screen at all.

The download went where the cache always keeps one, unpacked into a directory named with the
version, and **made read-only**, as lesson 3 said it would be:

```
ana@vm:~/mods-accents$ ls ~/mods-cache/golang.org/x
text@v0.42.0
ana@vm:~/mods-accents$ ls ~/mods-cache/golang.org/x/text@v0.42.0 | head -5
CONTRIBUTING.md
LICENSE
PATENTS
README.md
cases
ana@vm:~/mods-accents$ stat -c "%A %n" ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
-r--r--r-- /home/ana/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
ana@vm:~/mods-accents$ echo "// mine" >> ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
bash: line 1: /home/ana/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go: Permission denied
```

Every module of Ana's that asks for `golang.org/x/text v0.42.0` reads this same directory, so an
edit there would change programs you are not looking at. The go command makes it hard to do by
accident.

## go.sum, and who checks it

`go.sum` holds two lines per module version. The first is a hash of the module's files, the second a
hash of its `go.mod` alone. `h1:` names the method: the go command's source, in the package
`dirhash`, describes it as the base64 SHA-256 of a list of every file's own SHA-256 and name. **A
hash in `go.sum` is a promise about bytes**: whoever builds this module later, on any machine, must
get exactly these files or nothing.

That still leaves the first download. If the proxy had served altered files on the day `tidy` ran,
`go.sum` would have recorded the altered hash. So before writing a hash it has never seen, the go
command asks a second, independent service, the **checksum database**: a public log of the hashes of
module versions, which the package that implements it, `sumdb/tlog`, calls "tamper-evident".
`go env` names it, and you can ask it yourself:

```
ana@vm:~/mods-accents$ go env GOSUMDB
sum.golang.org
ana@vm:~/mods-accents$ curl -s https://sum.golang.org/lookup/golang.org/x/text@v0.42.0 | head -3
62562259
golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=
```

The first line is the record's number in the log; the next two are the lines of `go.sum`, character
for character. Everybody's go command checks against the same log, so a proxy that served one person
different bytes from everybody else would be caught by the hash. In the source, `modfetch/fetch.go`
consults the database only when the hash is not in `go.sum` already: from then on, `go.sum` is the
reference.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"What go mod tidy did the first time. One: it read main.go and found an import no module provides. Two: it asked proxy.golang.org which module provides the package and took the latest version, v0.42.0, with its .mod and .zip. Three: it hashed the files, h1:JbOZ. Four: it asked sum.golang.org whether the public log holds the same hash, which happens only for a hash go.sum does not have yet. Five: it wrote the require line and go.sum, and left the files in the module cache, read-only. Every later build compares the cache with go.sum and asks no one.\"><defs><marker id=\"tdy-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"tdy-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the first go mod tidy</text><rect x=\"10\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"72.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 read the imports</text><text x=\"72.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">main.go</text><text x=\"72.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an import no</text><text x=\"72.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">module provides</text><path d=\"M134 92 L150 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"152\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"214.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 ask the proxy</text><text x=\"214.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">proxy.golang.org</text><text x=\"214.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">latest version,</text><text x=\"214.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">v0.42.0 .mod .zip</text><path d=\"M276 92 L292 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"294\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 hash the files</text><text x=\"356.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">h1:JbOZ...</text><text x=\"356.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SHA-256 over</text><text x=\"356.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every file</text><path d=\"M418 92 L434 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"436\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 ask the log</text><text x=\"498.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sum.golang.org</text><text x=\"498.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same hash?</text><text x=\"498.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">first time only</text><path d=\"M560 92 L576 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"578\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5 write it down</text><text x=\"640.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">go.mod  go.sum</text><text x=\"640.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">files kept in the</text><text x=\"640.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cache, read-only</text><rect x=\"156\" y=\"180\" width=\"554\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"433\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">every later build</text><text x=\"433\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compares the files in the cache with go.sum, and asks no one</text><path d=\"M640.0 144 L640.0 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#tdy-wire)\"></path></svg>", "caption": "The first time a module version is fetched, two services are asked. After that, go.sum is the reference."}
```

The way to see `go.sum` doing its job is to make it disagree with the cache. Change one character of
the first hash, `Z` to `Y`, and build:

```
ana@vm:~/mods-accents$ sed -i "s/h1:JbOZ/h1:JbOY/" go.sum
ana@vm:~/mods-accents$ go build; echo $?
verifying golang.org/x/text@v0.42.0: checksum mismatch
	downloaded: h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
	go.sum:     h1:JbOYXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=

SECURITY ERROR
This download does NOT match an earlier download recorded in go.sum.
The bits may have been replaced on the origin server, or an attacker may
have intercepted the download attempt.

For more information, see 'go help module-auth'.
1
ana@vm:~/mods-accents$ sed -i "s/h1:JbOY/h1:JbOZ/" go.sum && go build && echo built
built
ana@vm:~/mods-accents$ go mod verify
all modules verified
```

The go command cannot tell a wrong `go.sum` from a wrong download, so it refuses both, and nothing
is built. That is why **`go.sum` is committed with `go.mod`**: without it, the next person's first
build is a first download, trusting whatever the network serves that day. `go mod verify` is the
check in the other direction, that nothing in the cache has been changed since it was downloaded.

## The whole graph, and which version wins

`go.mod` lists one requirement. The module graph behind it is larger, because `golang.org/x/text`
has a `go.mod` of its own:

```
ana@vm:~/mods-accents$ go list -m all
example.com/accents
golang.org/x/mod v0.41.0
golang.org/x/sync v0.23.0
golang.org/x/text v0.42.0
golang.org/x/tools v0.49.0
ana@vm:~/mods-accents$ go mod graph
example.com/accents go@1.27.1
example.com/accents golang.org/x/text@v0.42.0
go@1.27.1 toolchain@go1.27.1
golang.org/x/text@v0.42.0 golang.org/x/tools@v0.49.0
golang.org/x/text@v0.42.0 golang.org/x/mod@v0.41.0
golang.org/x/text@v0.42.0 golang.org/x/sync@v0.23.0
golang.org/x/text@v0.42.0 go@1.26.0
ana@vm:~/mods-accents$ go list -m golang.org/x/tools@latest
golang.org/x/tools v0.51.0
```

`go mod graph` prints one edge per line, a module and something it requires. `golang.org/x/text`
requires three more modules and Go 1.26.0 or later. Those three are in the graph and were never
downloaded: the empty cache of the first `tidy` received `x/text` and nothing else, and `go.sum` has
no line for them, because no package this program imports lives in them.

Then the versions. `x/tools` has a v0.51.0, and the graph chose v0.49.0. The rule is called
**minimal version selection**: every module states the lowest version of each dependency it works
with, and the go command picks, for each module in the graph, the highest of those stated minimums
and never anything newer. So a build does not change because somebody published a release overnight;
it changes when a `go.mod` changes, which lesson 40 does on purpose with `go get`.

## tidy removes, too

`tidy` makes `go.mod` match the imports in both directions. Take the program in `~/mods-unused`, the
same module with the last line of `main` and the import of `norm` deleted, and ask `tidy` what it would do
without letting it do it:

```
ana@vm:~/mods-unused$ go mod tidy -diff; echo $?
diff current/go.mod tidy/go.mod
--- current/go.mod
+++ tidy/go.mod
@@ -1,5 +1,3 @@
 module example.com/accents
 
 go 1.27.1
-
-require golang.org/x/text v0.42.0

diff current/go.sum tidy/go.sum
--- current/go.sum
+++ tidy/go.sum
@@ -1,2 +0,0 @@
-golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
-golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=

1
ana@vm:~/mods-unused$ go mod tidy && cat go.mod && wc -c go.sum
module example.com/accents

go 1.27.1
0 go.sum
ana@vm:~/mods-unused$ go mod tidy -diff; echo $?
0
```

`-diff` changes nothing, prints what `tidy` would change and exits 1 when that is anything at all.
That exit status is what makes it useful in a check that runs before code is merged: **a `go.mod`
that does not match the imports fails the check** instead of drifting until somebody notices. After
the real `tidy`, the requirement is gone and `go.sum` is empty.
