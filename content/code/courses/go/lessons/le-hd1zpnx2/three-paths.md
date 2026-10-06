---
title: Three ways to get a Go
version: 1
---

Every lesson from lesson 4 on asks you to type something and read what comes back, so you need a Go
toolchain on something you can type at. A Go toolchain is one directory: the `go` command, the
compiler it drives, and the source of the standard library. **There are three places to put it,
and the course recommends the first**: installed on your own computer.

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **installed** (recommended) | the official archive unpacked into `/usr/local/go` | one download, about a quarter of a gigabyte on disk, and caches that grow as you build | run as printed on Linux, and nearly so on macOS |
| **a virtual machine or a container** | a Linux system with Go inside it, apart from yours | a whole operating system's worth of disk, and memory reserved while it runs | run as printed, byte for byte, in an Ubuntu machine |
| **online** | a page at go.dev/play where you type a program and press Run | nothing at all | mostly unavailable: there is no terminal |

## Installed: the recommended path

The official route is an archive from **go.dev/dl**, one per operating system and processor, with
the SHA-256 of each file printed beside it so you can check the download before you trust it. On
Linux the instructions are two commands and a line in a file. It was **not run in this lab**,
because this machine cannot reach go.dev:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
```

The first line matters as much as the second. Unpacking a new release over an old
`/usr/local/go` leaves files of both behind, and a toolchain that is half one release and half
another fails in ways no message explains. **An upgrade is a delete and an unpack, never a merge.**
On macOS and Windows the same page offers an installer that does both steps for you.

The lab took the same release by another road. The go command can download a whole toolchain from
the **module proxy**, the server that also hands out every public Go module, and lesson 2 shows the
go command doing exactly that by itself. The proxy publishes when each release was built, and the
size of what it hands over:

```
ana@vm:~/setup$ curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.info; echo
{"Version":"v0.0.1-go1.27.1.linux-amd64","Time":"2026-08-28T16:20:06Z"}
ana@vm:~/setup$ curl -sL https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.zip | wc -c
75704807
```

About 76 MB to download, then. Unpacked, it is the directory every transcript in this course was
recorded with:

```
ana@vm:~/setup$ go version
go version go1.27.1 linux/amd64
ana@vm:~/setup$ cat /usr/local/go/VERSION
go1.27.1
time 2026-08-28T16:20:06Z
ana@vm:~/setup$ ls /usr/local/go
CONTRIBUTING.md
LICENSE
PATENTS
README.md
SECURITY.md
VERSION
bin
codereview.cfg
go.env
lib
pkg
src
ana@vm:~/setup$ ls /usr/local/go/bin
go
gofmt
ana@vm:~/setup$ du -sh /usr/local/go
253M	/usr/local/go
```

Two programs in `bin`, and 253 MB in all, most of it `src`: the source of the standard library,
which is what `go doc` read in lesson 4 with no network. The `VERSION` file carries the same build
time the proxy reported, so the lab's Go and the one go.dev serves are one release.

**Nothing outside that directory belongs to the toolchain.** Deleting `/usr/local/go` uninstalls
Go completely; the only other things it touched are the caches section 03 points at, which belong
to you.

## A virtual machine or a container

A virtual machine is a whole second computer inside yours. Install Ubuntu 24.04 in one, follow the
installed path inside it, and every transcript in this course matches what you see, prompt and all.
That is worth something on Windows, where some commands around Go in these lessons, like `file`
and `du`, do not exist in the ordinary shell. WSL, the Linux that Windows can run, is one such
machine. The price is disk for a whole operating system and memory that the virtual machine holds while it
runs, which an older laptop feels.

A container is lighter. The official `golang` image carries the release as `golang:1.27.1` on
Docker Hub, and a command like the one below starts a shell in it with your current directory
mounted inside. It was **not run in this lab** either:

```sh
docker run --rm -it -v "$PWD":/work -w /work golang:1.27.1 bash
```

`--rm` throws the container away when you leave the shell, so anything you did not save into
`/work` goes with it, including the module downloads of lesson 38. Docker itself has to be
installed first, which on macOS and Windows means running a virtual machine anyway.

## Online

The **Go Playground**, at go.dev/play, compiles and runs one program on a server and shows you what
it printed. It costs your computer nothing and it is a fine place to try a fragment from lessons 5
to 10. It was not used for this course, because what it lacks is everything around the program.
There is no terminal, so no `go build`, no `go install`, no `go mod`, no `go doc`, and no files of
your own between visits. From lesson 4 on, most of what this course types has nowhere to go there.

So: **install it if you can, use a Linux virtual machine if you want the transcripts exact, and
keep the Playground for the bus.**
