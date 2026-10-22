---
title: protoc and the two Go plugins
version: 1
---

Turning a `.proto` file into Go takes three programs. **`protoc`**, the Protocol Buffers compiler, reads
the file and understands it; for each language it hands the result to a **plugin**, a separate program
named `protoc-gen-<something>`, which writes the code. Go needs two: **`protoc-gen-go`** writes the
message types, and **`protoc-gen-go-grpc`** writes the client and server.

## Three ways to get protoc

| path | what it costs | for this course |
|---|---|---|
| **Ubuntu's package**, `protobuf-compiler` (recommended) | about 5 MB with its two libraries, from the archive you already use | release 3.21.12, the one every transcript used |
| **a release archive** from the protobuf project's GitHub page | one download, unpacked into a directory on your `PATH` | a newer release; the generated Go is the same for this file |
| **`buf`**, a separate tool that replaces `protoc` | one more program to learn, with its own configuration file | a good choice for a team; not used here |

```sh
sudo apt install -y protobuf-compiler
```

The plugins are Go programs, installed with `go install` at pinned versions, like sqlc in lesson 8:

```
ana@vm:~$ protoc --version
libprotoc 3.21.12
ana@vm:~$ go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12
ana@vm:~$ go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2
ana@vm:~$ protoc-gen-go --version; protoc-gen-go-grpc --version
protoc-gen-go v1.36.12
protoc-gen-go-grpc 1.6.2
```

**protoc 3.21.12, protoc-gen-go v1.36.12 and protoc-gen-go-grpc 1.6.2.** The generated files record the
versions that made them, so a team pins all three, as it pins sqlc.

## When a plugin cannot be found

protoc finds a plugin by its name on your `PATH`, and the plugins live in `~/go/bin`. A shell whose
`PATH` lacks that directory, the most common mistake on a new machine, gets this:

```
ana@vm:~/boxoffice$ PATH=/usr/bin:/bin protoc --go_out=. --go_opt=module=example.com/boxoffice proto/seats.proto
protoc-gen-go: program not found or is not executable
Please specify a program using absolute path or make sure the program is available in your PATH system variable
--go_out: protoc-gen-go: Plugin failed with status code 1.
```

**`program not found or is not executable` is about `PATH`, not about protoc.** The fix is lesson 1
section 02's second line in `~/.profile`, `export PATH=$PATH:$HOME/go/bin`, and a new login. If protoc
itself is missing, the shell says `command not found` before protoc is involved at all.
