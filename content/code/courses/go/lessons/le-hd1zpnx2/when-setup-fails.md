---
title: When the setup fails
version: 1
---

A setup that fails rarely says "your setup failed". It says something about a file, a version or a
server, and the temptation is to reinstall everything and hope. **Each failure below has one cause,
and the message names it** if you read the message to its end. All three were produced on purpose
in the lab.

## `go: command not found`

The shell looked through every directory in `PATH`, found no program called `go`, and gave up
before Go was involved at all:

```
ana@vm:~/setup$ PATH=/usr/bin:/bin; go version; echo $?
bash: line 1: go: command not found
127
ana@vm:~/setup$ PATH=/usr/bin:/bin; . ~/.profile; go version
go version go1.27.1 linux/amd64
```

**Exit status 127 is the shell's own number for "no such command"**, so the message is from
`bash` and not from Go. The installation is fine; only `PATH` is wrong. Two causes cover nearly
every case: the lines of section 03 were never added to `~/.profile`, or they were and this
terminal was opened before they existed. The second command above is the repair for the second
case: read the file again with `.`, or log out and back in.

The mirror image has the same cause. If `go version` prints an older release than the one you just
unpacked, another `go` sits earlier in `PATH`, perhaps one a package manager installed years ago.
`command -v go` names the file that actually runs.

## `go.mod requires go >= …`

A module says in its `go.mod` which Go it was written for, and a toolchain older than that refuses
to build it. Go 1.28 has not been released as this is written, so a `go.mod` asking for it is a safe
way to see the refusal:

```
ana@vm:~/setup-new$ go run .; echo $?
go: go.mod requires go >= 1.28 (running go 1.27.1; GOTOOLCHAIN=local)
1
```

Everything needed is in the parentheses. The module wants 1.28, the toolchain running is 1.27.1,
and `GOTOOLCHAIN=local` says the go command was told not to fetch another. That last part is this
lab's choice, made in its environment, as section 03 showed. With the default `auto`, the go
command would download the release the module asks for and carry on, as lesson 2 shows.

So there are two ways out. **Install the newer release** the way section 02 did, or let the go
command fetch it by not forcing `local`. Editing the `go` line in `go.mod` down to your version
hides the message without making the code any older. It may use something your release does not
have, and then the failure reappears as a compile error that is harder to read.

## A module proxy that cannot be reached

The first time a module needs something it has not got, the go command asks the module proxy for
it. If the proxy cannot be reached, the message is long and reads left to right, from what was
wanted to why it was not had:

```
ana@vm:~/setup-proxy$ GOPROXY=https://proxy.invalid go get golang.org/x/text@latest; echo $?
go: golang.org/x/text@latest: module golang.org/x/text: Get "https://proxy.invalid/golang.org/x/text/@v/list": dial tcp: lookup proxy.invalid on 8.8.8.8:53: no such host
1
ana@vm:~/setup-proxy$ go env GOPROXY
https://proxy.golang.org,direct
```

The first two fields are what was asked for, `golang.org/x/text` at its latest version. The `Get`
is the address the go command tried. Everything after the last colon is the reason: the machine's
name server, `8.8.8.8`, knows no host called `proxy.invalid`. `.invalid` is a name reserved so that
it never resolves, which made it a safe broken proxy for the demonstration.

**When a download fails, look at `GOPROXY` before you look at the network.** It came from one of
the three places in section 03. The usual culprit is a value somebody set months ago, in a shell,
in `go env -w` or in a company's setup script. `go env -u GOPROXY` returns your own file to the
release's default. If the network is the problem, the same line says so in other words: a timeout,
a refused connection, a certificate it does not trust.

## A short check, before you ask anyone

Four commands answer most questions about a Go installation, and they are what anybody helping you
will ask for first:

1. `go version`: which release runs, and whether there is one at all.
2. `command -v go`: which file that is.
3. `go env GOROOT GOPATH`: where it thinks it lives and where your downloads go.
4. `go env -changed`: every setting that is not the default, wherever it came from.
