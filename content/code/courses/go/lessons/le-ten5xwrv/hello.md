---
title: The program, line by line
version: 1
---

A first program in most languages is one line. In Go it is eight, and the extra seven are not
ceremony: **each one is a rule of the language you will meet in every file you ever write.** Here
is the whole thing, in a directory of its own, `~/hello`:

```schooling-example
{
  "language": "go",
  "file": "hello.go",
  "parts": [
    {
      "code": "// Command hello prints a greeting.\n",
      "note": "**A comment above the package clause is the package's documentation.** For a program it starts with the word `Command` and the program's name, by convention, and `go doc` prints it (section 03)."
    },
    {
      "code": "package main\n",
      "note": "**Every Go file starts by naming its package.** `main` is the one special name: a package called `main` builds into a program you can run, and any other name builds into a library somebody imports."
    },
    {
      "code": "\nimport \"fmt\"\n",
      "note": "**What the file uses from elsewhere, named by import path.** `fmt` is the standard library's formatting package. An import the file does not use is a compile error, not a warning; section 04 shows it."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(\"Hello, Go\")\n}\n",
      "note": "**`main` in package `main` is where the program starts**, and it takes no arguments and returns nothing. `fmt.Println` is the function `Println` from the package `fmt`: the capital P is what lets another package call it, which is lesson 39's subject."
    }
  ]
}
```

The indentation inside `main` is a tab, not spaces. Nobody chose that by hand: it is what `gofmt`
writes, and section 04 is about why every Go file in the world is laid out by the same program.

## Running it

The quickest way to see it work is `go run` with the file's name:

```
ana@vm:~/hello$ go run hello.go
Hello, Go
```

That works for a single file and stops working soon after. A real program is a **module**, a
directory with a `go.mod` file at its root that says what the code is called and which Go it was
written for. `go mod init` writes one:

```
ana@vm:~/hello$ go mod init example.com/hello
go: creating new go.mod: module example.com/hello
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/hello$ cat go.mod
module example.com/hello

go 1.27.1
ana@vm:~/hello$ go run .
Hello, Go
```

Two lines, and both matter. `module example.com/hello` is the module's **path**, the name another
program would import it by; `example.com` is a domain reserved for examples, so nothing real
answers there. `go 1.27.1` is the version of the language this module expects, written from the
toolchain that ran the command. The `go mod tidy` hint is about dependencies, and this program has
none; lesson 38 is where it earns its keep.

With a `go.mod` in place, `go run .` means "the package in this directory", whatever its files
are called. That is the form the rest of this course uses.

**A Go program does not need a class, an object or a file named after anything.** It needs a
package called `main` with a function called `main` in it. Everything else in the file above is
what that program happens to do.
