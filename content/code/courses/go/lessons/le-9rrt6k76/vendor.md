---
title: go mod vendor, and what a copy costs
version: 1
---

Somebody arriving from JavaScript expects a directory full of dependencies beside the code, and
looks for Go's. There is none: section 03 built the program with `golang.org/x/text` living in the
module cache, outside the module, shared by every module on the machine. **A `vendor` directory is
optional in Go**, a copy you ask for, and no module in this course has needed one so far. This
section makes one in `~/mods-vendor`, a copy of `~/mods-accents` after its `tidy`, and then counts
what it costs.

```
ana@vm:~/mods-vendor$ go mod vendor
ana@vm:~/mods-vendor$ find vendor -type f | sort
vendor/golang.org/x/text/LICENSE
vendor/golang.org/x/text/PATENTS
vendor/golang.org/x/text/transform/transform.go
vendor/golang.org/x/text/unicode/norm/composition.go
vendor/golang.org/x/text/unicode/norm/forminfo.go
vendor/golang.org/x/text/unicode/norm/input.go
vendor/golang.org/x/text/unicode/norm/iter.go
vendor/golang.org/x/text/unicode/norm/normalize.go
vendor/golang.org/x/text/unicode/norm/readwriter.go
vendor/golang.org/x/text/unicode/norm/tables15.0.0.go
vendor/golang.org/x/text/unicode/norm/tables17.0.0.go
vendor/golang.org/x/text/unicode/norm/transform.go
vendor/golang.org/x/text/unicode/norm/trie.go
vendor/modules.txt
ana@vm:~/mods-vendor$ cat vendor/modules.txt
# golang.org/x/text v0.42.0
## explicit; go 1.26.0
golang.org/x/text/transform
golang.org/x/text/unicode/norm
```

`go mod vendor` printed nothing, as the go command does when it succeeds. It did not copy the
module; it copied **the packages the build needs**: `norm` and the package `transform` that `norm`
imports. With them came `LICENSE` and `PATENTS` from the module's root, which the go command's
source lists among the "metadata files" it copies beside any package it vendors.
`vendor/modules.txt` is the index. A `#` line names a module and its version, `## explicit` says
`go.mod` requires it by name, and the lines under it are the packages taken from it.

```
ana@vm:~/mods-vendor$ du -sh vendor ~/go/pkg/mod/golang.org/x/text@v0.42.0
920K	vendor
30M	/home/ana/go/pkg/mod/golang.org/x/text@v0.42.0
ana@vm:~/mods-vendor$ find ~/go/pkg/mod/golang.org/x/text@v0.42.0 -type f | wc -l
487
ana@vm:~/mods-vendor$ du -k vendor/golang.org/x/text/unicode/norm/tables*
388	vendor/golang.org/x/text/unicode/norm/tables15.0.0.go
396	vendor/golang.org/x/text/unicode/norm/tables17.0.0.go
```

Fourteen files against the module's 487, and 920 KB against 30 MB. Of the 920, 784 are the two
`tables` files: Unicode's data, for two editions of the standard, written out as Go.

## The build uses it without being asked

`go build` takes the packages from `vendor` whenever the directory exists and the `go` line in
`go.mod` says 1.14 or later. Nothing on the command line changes, so the evidence has to be asked
for. `go list` prints where the source of a package comes from:

```
ana@vm:~/mods-vendor$ go list -f "{{.Dir}}" golang.org/x/text/unicode/norm
/home/ana/mods-vendor/vendor/golang.org/x/text/unicode/norm
ana@vm:~/mods-vendor$ GOPROXY=off GOMODCACHE=/nowhere go build -o accents . && ./accents
"cafe\u0301" is 6 bytes
"caf\u00e9" is 5 bytes
equal as typed:   false
equal after NFC:  true
ana@vm:~/mods-vendor$ go list -m all
go: can't compute 'all' using the vendor directory
	(Use -mod=mod or -mod=readonly to bypass.)
```

The second command is the reason vendoring exists. `GOPROXY=off` forbids every download and
`GOMODCACHE=/nowhere` points the module cache at a directory that does not exist, and the build
still worked. **A vendored module builds from its own directory and nothing else**, which is what a
build machine with no network access needs. The rule about `go 1.14` is in the go command's own
source, `modload/init.go`, which gives the reason it switched to the vendor directory as "Go version
in go.mod is at least 1.14 and vendor directory exists."

The third command is the price showing. `vendor` holds packages, not the module graph of section 03,
so a question about the whole graph has nothing to read. The message names the way round it:
`-mod=mod` tells a single command to ignore `vendor` and use the module cache.

## When go.mod and vendor disagree

A copy can go stale. Lesson 40 changes requirements with `go get`; here `go mod edit` stands in for
it and moves the requirement to an older release without touching `vendor`:

```
ana@vm:~/mods-vendor$ go mod edit -require=golang.org/x/text@v0.41.0
ana@vm:~/mods-vendor$ go build; echo $?
go: inconsistent vendoring in /home/ana/mods-vendor:
	golang.org/x/text@v0.41.0: is explicitly required in go.mod, but not marked as explicit in vendor/modules.txt
	golang.org/x/text@v0.42.0: is marked as explicit in vendor/modules.txt, but not explicitly required in go.mod

	To ignore the vendor directory, use -mod=readonly or -mod=mod.
	To sync the vendor directory, run:
		go mod vendor
1
ana@vm:~/mods-vendor$ go mod tidy && go mod vendor && head -2 vendor/modules.txt
# golang.org/x/text v0.41.0
## explicit; go 1.25.0
ana@vm:~/mods-vendor$ go build && echo built
built
```

The go command compared the two files line by line and refused to guess which one you meant. That
refusal is what `modules.txt` is for. Without it, a build could quietly compile v0.42.0 while
`go.mod` promised v0.41.0, and the binary would not be the program the module describes. `tidy`
first, because the new version needs its lines in `go.sum`; then `vendor`, to copy it.

## Whether to vendor

Without `vendor`, a build is already reproducible: `go.mod` fixes the versions, `go.sum` fixes the
bytes, and the proxy and the checksum database serve the same answer to everybody. What vendoring
adds is independence from those services, at a cost you pay on every change.

| | without `vendor` | with `vendor` |
|---|---|---|
| what the repository holds | `go.mod` and `go.sum`, a few lines | those, plus a copy of every package the build uses |
| a build needs | the module cache, or the network to fill it | the repository, and nothing else |
| a dependency upgrade shows in review as | a changed line in `go.mod` and two in `go.sum` | the same, plus every changed file of the dependency |
| after a requirement changes | nothing more | `go mod vendor` as well, or the build refuses |

So the default is **no `vendor`**, and the reasons to add one are particular. A build may have to
run with no network, a rule may say that every line compiled into the binary sits in the repository
where a reviewer reads it, or a dependency may disappear from where it was published. Your own
modules in this course stay without one.
