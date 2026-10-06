---
title: run, build and install
version: 1
---

`go run` looks like an interpreter: you give it source and the program's output comes back. **It
is not one.** Go has no interpreter. `go run` compiles the program to a binary, runs the binary,
and keeps it in the go command's **build cache** in case you ask again. The cache is easy to see
by emptying it first:

```
ana@vm:~/hello$ go clean -cache
ana@vm:~/hello$ time go run .
Hello, Go

real	0m4.493s
user	0m10.340s
sys	0m1.611s
ana@vm:~/hello$ time go run .
Hello, Go

real	0m0.044s
user	0m0.060s
sys	0m0.032s
```

The first run took four and a half seconds, and almost none of that was the greeting: with the
cache empty, the go command recompiled the parts of the standard library this program uses before
compiling the program itself. The second run took 44 milliseconds, because nothing had changed and
the binary was already there. Change one character of `hello.go` and only this package is
compiled again; the standard library stays in the cache.

What `go run` does not do is leave a file you can find. The binary sits inside the cache, which the go
command manages and nobody browses. That is fine while you are trying things and wrong for anything
you mean to keep.

## go build: a file you can hand to somebody

`go build` compiles the package in the current directory and leaves the binary next to the source,
named after the last element of the module path:

```
ana@vm:~/hello$ go build
ana@vm:~/hello$ wc -c go.mod hello.go hello
     36 go.mod
    106 hello.go
2342465 hello
2342607 total
ana@vm:~/hello$ ./hello
Hello, Go
ana@vm:~/hello$ file hello
hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=TSzTWGWavtvuaa9Lv40Z/FyHeT0PVUvKjCUEZRLRW/hreRnSolAyQtmBmaupMF/MGfJ8Lr9sq7zDRhl_sZI, BuildID[sha1]=75793a032d6b4283f7e1db392dc303cf4d6c468d, with debug_info, not stripped
```

**106 bytes of source became 2,342,465 bytes of program**, and `go build` printed nothing at all,
which is how the go command says it succeeded. The size is not the greeting. It is the Go
**runtime**, which every Go program carries inside it: the garbage collector of lesson 24, the
scheduler, the code that prints a stack trace when something panics. A program written in C
borrows most of that from libraries already on the machine; a Go program brings its own.

That is what `statically linked` in the `file` line means, and it is the trade lesson 1 described.
The binary asks the machine for a kernel and nothing else, so you can copy this one file to
another Linux machine of the same architecture and run it there. There is no runtime to install
first and no library version to match.

`-o` names the output something else, which is how you build without caring what the module is
called:

```
ana@vm:~/hello$ go build -o greet .
ana@vm:~/hello$ ./greet
Hello, Go
```

## go install: on your PATH

`go install` builds the same binary and puts it in the directory the go command uses for
programs, `~/go/bin` unless you set `GOBIN`. Lesson 3 put that directory on the lab's `PATH`, so
the program then runs by name, from anywhere:

```
ana@vm:~/hello$ go install
ana@vm:~/hello$ ls ~/go/bin
hello
ana@vm:~/hello$ cd ~ && hello
Hello, Go
```

So the three commands do the same compiling, and differ in **where the binary ends up**:

| command | compiles | the binary goes to | use it for |
|---|---|---|---|
| `go run .` | yes, without debugger information | the build cache, and it runs it | trying things |
| `go build` | yes | the current directory | a file to copy somewhere |
| `go install` | yes | `~/go/bin` (or `GOBIN`) | a tool you want to run by name |

All three share the build cache from the start of this section, so building after running costs
almost nothing: whatever was compiled for one is reused by the others.
