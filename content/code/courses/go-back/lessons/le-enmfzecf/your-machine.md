---
title: Your machine, as go-concurrency left it
version: 1
---

This course writes a server and talks to it from a terminal, so before the first line of code you
need two things answering on your own computer: **Go 1.27.1 and `curl`**. Neither is new. The `go`
course built this environment in lesson 3, and `go-concurrency` used it for thirty lessons; if you
came through them, check it below and move on. If you came here some other way, the next few
paragraphs are the setup in brief, and `go` lesson 3 is the same setup in full.

The platform gives you no machine. Everything in this course is typed on a computer you control,
and **every transcript was recorded on Ubuntu 24.04**, as a user called `ana` on a machine called
`vm`, which is why the prompt reads `ana@vm`.

## Three places to run it

| path | what it costs your computer | the transcripts |
|---|---|---|
| **installed** (recommended) | Go's 253 MB directory, plus caches that grow with every module you download | run as printed on Linux, and nearly so on macOS |
| **a virtual machine** with Ubuntu 24.04 | a whole operating system's worth of disk, and memory held while it runs | run as printed, byte for byte |
| **online**, in the Go Playground | nothing | mostly unusable: it runs one program and shows its output, with no terminal to type `curl` in |

**Install it if you can.** A virtual machine is worth its cost on Windows, where `curl` behaves
differently and some commands in these lessons do not exist; WSL, the Linux that Windows can run,
counts as one. The Playground is fine for checking what a function returns and useless for a
server, which is the whole subject here.

Later lessons add two more things, each installed in the lesson that first needs it, with its own
paths and its own section on what fails: **PostgreSQL 16 in lesson 6 and a container engine in
lesson 16.** A third, the C compiler `gcc`, is the one `go-concurrency` lesson 1 installed for the
race detector; lesson 8 needs it too, and says how to get it if you did not take that course.

## The setup in brief

On Linux, Go is one archive from go.dev/dl unpacked into `/usr/local/go`, after deleting whatever
was there, and two lines in `~/.profile`. These are the commands `go` lesson 3 runs; they were not
run again for this course:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
```

Log out and in again, so that the shell reads the file. `curl` comes with most Ubuntu
installations; if the check below says it is missing, `sudo apt install curl` adds it.

## The check

```
ana@vm:~/boxoffice$ go version
go version go1.27.1 linux/amd64
ana@vm:~/boxoffice$ go env GOROOT GOPATH GOTOOLCHAIN
/usr/local/go
/home/ana/go
local
ana@vm:~/boxoffice$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
```

Three answers to read. **The release is 1.27.1**, the one every transcript was recorded with; a
newer 1.27 behaves the same, and an older release may lack something a later lesson uses.
`GOROOT` is the directory you unpacked. `GOTOOLCHAIN=local` is the lab's choice, and it makes the
go command refuse a module that asks for a newer Go instead of downloading one; on your machine it
probably says `auto`, and either is fine.

The project lives in a directory of its own, and its module needs a name. Any name works for a
program nobody imports; this one follows the habit of a domain you control:

```
ana@vm:~/boxoffice$ go mod init example.com/boxoffice
go: creating new go.mod: module example.com/boxoffice
ana@vm:~/boxoffice$ cat go.mod
module example.com/boxoffice

go 1.27.1
```

## When it does not answer

**`go: command not found` is the shell, not Go**: the two lines are missing from `~/.profile`, or
this terminal was opened before they were there. **An older `go version` than you installed** means
another `go` sits earlier in `PATH`, and `command -v go` names it. `go` lesson 3, section 05, takes
each of these apart with its exact message, and a proxy that cannot be reached as well.

One more, which this course meets and the `go` course did not. **A server needs a port, and only
one program at a time may listen on it.** The next section shows the message you get when something else
already holds port 8080, and what to do about it.
