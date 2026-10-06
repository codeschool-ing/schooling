---
title: What was installed, and where it lives
version: 1
---

Unpacking the archive puts a program on the disk. It does not make `go` a command. **Your shell
runs a command only when the command sits in one of the directories listed in `PATH`**, and
`/usr/local/go/bin` is in none of them until you add it. The usual place to add it is `~/.profile`,
which the shell reads each time you log in. Ana added two lines:

```
ana@vm:~/setup$ echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
ana@vm:~/setup$ echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
ana@vm:~/setup$ tail -2 ~/.profile
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
```

The single quotes keep `$PATH` and `$HOME` as written, so the file holds the recipe rather than
today's value. The first line is for `go` and `gofmt`. The second is for the programs **you** build
with `go install`, which land in `~/go/bin`; that line is how `hello` runs by name from `~` in
lesson 4.

The file takes effect at the next login. To see what a fresh login gets, without logging out,
start from a `PATH` that knows nothing of Go and read the file with `.`:

```
ana@vm:~/setup$ PATH=/usr/bin:/bin; . ~/.profile; echo $PATH; command -v go gofmt
/usr/bin:/bin:/usr/local/go/bin:/home/ana/go/bin
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
```

Both directories arrived at the end of `PATH`, and `command -v` names the file the shell would run
for each word. **If `command -v go` prints nothing, nothing else in this course will work**, and
section 05 starts there.

## Where the go command keeps things

`go env` prints the go command's settings, and given names it prints just those. Five of them say
where everything lives:

```
ana@vm:~/setup$ go env GOROOT GOPATH GOBIN GOMODCACHE GOCACHE
/usr/local/go
/home/ana/go
/home/ana/go/bin
/home/ana/go/pkg/mod
/home/ana/.cache/go-build
```

Nobody set any of these. Each is a default the go command worked out from where it was installed
and from Ana's home directory. Drawn out, they are three directories with three different jobs:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Where a Go installation keeps things. GOROOT, /usr/local/go, holds the toolchain: go, gofmt and the standard library&#x27;s source, replaced whole on an upgrade. GOPATH, ~/go, holds bin, where go install puts programs, and pkg/mod, the read-only module downloads. GOCACHE, ~/.cache/go-build, holds compiled packages and is safe to empty. PATH points at /usr/local/go/bin and ~/go/bin. Your own code lives anywhere else.\"><defs><marker id=\"gr-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">PATH</text><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the shell finds commands only in these two</text><rect x=\"20\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOROOT</text><text x=\"125\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/local/go</text><rect x=\"40\" y=\"124\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/  go  gofmt</text><text x=\"125\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the toolchain</text><text x=\"125\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">go, gofmt and the standard</text><text x=\"125\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">library&#x27;s source</text><text x=\"125\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">replaced whole on an upgrade</text><rect x=\"255\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOPATH</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/go</text><rect x=\"275\" y=\"124\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/   (GOBIN)</text><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">programs go install built</text><rect x=\"275\" y=\"180\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pkg/mod/   (GOMODCACHE)</text><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">downloaded modules, read-only</text><rect x=\"490\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOCACHE</text><text x=\"595\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/.cache/go-build</text><text x=\"595\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">compiled packages</text><text x=\"595\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">safe to empty: go clean -cache</text><path d=\"M360 48 V56 M200 56 H420\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 56 V122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-phosphor)\"></path><path d=\"M420 56 V122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-phosphor)\"></path><rect x=\"20\" y=\"256\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your code: anywhere at all, e.g. ~/hello, ~/setup-work</text></svg>", "caption": "Three directories the go command owns, and the two bin directories PATH must name. Your code is in none of them."}
```

`GOROOT` is the toolchain from section 02, and you never write in it. `GOPATH` is `~/go`, and two
other values are inside it: `GOBIN`, where `go install` puts programs, and `GOMODCACHE`, where
downloaded modules are kept, unpacked and read-only, from lesson 38 on. `GOCACHE` is the build
cache that makes the second `go run` of lesson 4 take 44 milliseconds. **Everything under `GOPATH`
and `GOCACHE` can be deleted and comes back on demand**, at the price of a download or a rebuild:
`go clean -cache` empties the one and `go clean -modcache` the other.

## One program, many commands

`go` is a single program, and the word after it chooses what it does. `go help` lists the words:

```
ana@vm:~/setup$ go help | head -27
Go is a tool for managing Go source code.

Usage:

	go <command> [arguments]

The commands are:

	bug         start a bug report
	build       compile packages and dependencies
	clean       remove object files and cached files
	doc         show documentation for package or symbol
	env         print Go environment information
	fix         apply fixes suggested by static checkers
	fmt         gofmt (reformat) package sources
	generate    generate Go files by processing source
	get         add dependencies to current module and install them
	install     compile and install packages and dependencies
	list        list packages or modules
	mod         module maintenance
	run         compile and run Go program
	telemetry   manage telemetry data and settings
	test        test packages
	tool        run specified go tool
	version     print Go version
	vet         report likely mistakes in packages
	work        workspace maintenance
```

Lesson 4 uses six of them: `run`, `build`, `install`, `doc`, `fmt` and `vet`. `work`
is section 04 of this lesson, `mod` is lesson 38 and `get` lesson 40; `test` belongs to the
`go-concurrency` course. `go help` followed by any of these words prints its full manual, and the
rest of the list, which `head` cut off, is topics such as `go help gopath`.

## Settings, and who wins

A setting can come from three places, and **the go command reads them in a fixed order, the last
one winning**. First the file `go.env` inside `GOROOT`, which ships with the release. Then a file
of your own, written by `go env -w`. Then the environment of the shell, which beats both.
`go env -changed` lists whatever differs from the defaults:

```
ana@vm:~/setup$ go env -changed
GOTOOLCHAIN='local'
ana@vm:~/setup$ grep -v "^#" /usr/local/go/go.env

GOPROXY=https://proxy.golang.org,direct
GOSUMDB=sum.golang.org

GOTOOLCHAIN=auto
ana@vm:~/setup$ go env -w GOTOOLCHAIN=auto
warning: go env -w GOTOOLCHAIN=... does not override conflicting OS environment variable
ana@vm:~/setup$ cat ~/.config/go/env
GOTOOLCHAIN=auto
ana@vm:~/setup$ go env GOTOOLCHAIN
local
ana@vm:~/setup$ go env -u GOTOOLCHAIN
```

The release says `GOTOOLCHAIN=auto`: when a module asks for a newer Go, download it, which is
lesson 2's subject. The lab's environment says `local`, so that every transcript in this course
comes from 1.27.1 and nothing else. `go env -w` wrote `auto` into Ana's own file and warned, in the
same breath, that it would make no difference; `go env GOTOOLCHAIN` confirms the environment won.
`go env -u` took the line out again.

Two of the other defaults in `go.env` matter in section 05. `GOPROXY` is where modules are
downloaded from, the proxy first and the module's own repository after it, and `GOSUMDB` is the
checksum database that confirms a download is the one everybody else got.
