---
title: The lab this course runs on
version: 1
---

Every lesson in this course has you type something and read what comes back, so it needs a machine
you can type at. **The platform gives you none.** You build it, and you already have most of it if
you took the two courses before this one: this course runs on the same lab, at the same versions,
and adds to it only where a lesson needs something new.

| what | which | built in full by |
|---|---|---|
| the Go toolchain | **Go 1.27.1**, the official archive in `/usr/local/go` | `go`, lesson 3 |
| two directories on `PATH` | `/usr/local/go/bin` and `~/go/bin` | `go`, lesson 3 |
| a C compiler | `gcc` from Ubuntu 24.04's archive | `go-concurrency`, lesson 16, for the race detector |
| a container runtime | Podman from Ubuntu 24.04's archive | this course, lesson 17, before lesson 18 uses it |

The C compiler waits until lesson 15, where the race detector needs it, and lesson 23, where Go
calls C. The tools the lessons install with `go install`, like Cobra's generator or the linters of
lesson 8, are downloaded by the go command when their lesson asks for them, and land in `~/go/bin`.

## The steps, in brief

On Ubuntu 24.04 it comes to this. The first two lines unpack the archive you downloaded from
go.dev/dl, after checking its SHA-256 against the one printed beside it; the next two put both
directories on your `PATH` at your next login; the last one installs the compiler:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
sudo apt install gcc
```

**The two `tar` lines were not run in this lab**, because this machine cannot reach go.dev. The lab
took the same release from the Go module proxy instead, which is the route `go` lesson 3 shows and
checks, and `gcc` was already installed. Everything else in this course was typed as you see it.

## Four checks before lesson 1 goes on

Log out and in again, or open a new terminal, so that `~/.profile` is read. Then ask each tool to
answer. Ana, the student in every transcript of this course, works in `~/hits`, the directory this
lesson's program lives in:

```
ana@vm:~/hits$ go version
go version go1.27.1 linux/amd64
ana@vm:~/hits$ command -v go gofmt gcc
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
/usr/bin/gcc
ana@vm:~/hits$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
ana@vm:~/hits$ go env GOROOT GOPATH CGO_ENABLED
/usr/local/go
/home/ana/go
1
ana@vm:~/hits$ echo $PATH | tr : "\n" | grep go
/usr/local/go/bin
/home/ana/go/bin
```

**`go version` must say 1.27.1**, because every transcript in this course was recorded with it and
some lessons quote what its compiler printed. `command -v` names the file the shell would run for
each word, and three files mean three tools found. `CGO_ENABLED=1` is the go command saying it found
a C compiler and will use it when asked to. The last line shows both `bin` directories on the path.

## Three ways to have the machine

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Go and `gcc` on your own Linux or macOS | about 250 MB for Go, about 160 MB for the compiler and the libraries it brings, and caches that grow as you build | match on Ubuntu 24.04; on macOS the commands match and a few outputs differ |
| **a virtual machine** | Ubuntu 24.04 in a VM, then the steps above inside it | a whole operating system's disk, and the memory you give it while it runs | match byte for byte |
| **online** | the Go Playground at go.dev/play | nothing | almost none: there is no terminal |

**This course is the one where the online path stops being useful.** The Playground compiles one
file and shows you what it printed. This course is about everything around that file: the
command line, the build, the linters, the profiler, a binary for another machine. None of that has
anywhere to go in a web page. Keep the Playground for trying a fragment of lesson 21's reflection on
the bus.

A virtual machine is the right choice on Windows. WSL, the Linux that Windows runs for you, is one,
and Multipass or VirtualBox will give you a full Ubuntu 24.04 with a few clicks. Give it 2 GB of
memory and 20 GB of disk; lessons 12 to 14 profile a program that reads a hundred megabytes, and the
container images of lesson 18 want room.

## When the setup fails

Two failures account for nearly everyone who gets stuck here. The first is a shell that cannot find
`go` at all. To see what that looks like, take the two directories off `PATH` for one command:

```
ana@vm:~/hits$ PATH=/usr/bin:/bin; go version; echo $?
bash: line 1: go: command not found
127
```

**Exit status 127 is the shell's own code for "no such command"**, and it means the program never
ran. The archive may be unpacked perfectly; the shell simply does not look in `/usr/local/go/bin`.
Check that the two `export` lines are at the end of `~/.profile`, then log in again: a terminal opened
before you added them keeps the old `PATH` until it is closed.

The second shows up only in lesson 15, which is why it is worth seeing now. With no C compiler on the
path, the go command quietly turns cgo off, and the race detector refuses to build. Here it is on a
`PATH` that has everything in `/usr/bin` except `gcc`:

```
ana@vm:~/race$ PATH=/usr/local/go/bin:$HOME/nogcc; go env CGO_ENABLED; go build -race; echo $?
0
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
ana@vm:~/race$ go build -race && echo built
built
```

The message suggests setting `CGO_ENABLED=1`, which is half the answer: cgo still needs a compiler to
run. **`CGO_ENABLED` printing `0` on a machine where you did not set it means the go command looked
for `gcc` and did not find it.** `sudo apt install gcc` is the fix, and the second command, back on
the ordinary `PATH`, builds.
