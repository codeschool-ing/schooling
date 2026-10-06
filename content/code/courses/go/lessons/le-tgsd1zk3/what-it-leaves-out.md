---
title: What Go leaves out
version: 1
---

A language is usually judged by what it has, and a newcomer to Go goes looking for the features they
know: classes, inheritance, exceptions, a `while` loop. **Go is defined as much by what it leaves
out, and it left those out on purpose.** Each missing feature is a thing the designers had watched
cost time in large programs, and the time they meant was a reader's: the next person to open the
file.

## Twenty-five words

The quickest way to see the size of a language is to count its keywords, the words you may not use
as names because the grammar owns them. The standard library includes Go's own parser, in
`go/token`, so a program can ask it:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command keywords lists the keywords of Go, as the standard library's parser knows them.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"go/token\"\n\t\"strings\"\n)\n",
      "note": "**`go/token` is the package that names every token the Go parser knows**: operators, punctuation, literals and keywords. The go command, `gofmt` and `go vet` all read Go with the same packages."
    },
    {
      "code": "\nfunc main() {\n\tvar words []string\n\tfor tok := token.ILLEGAL; tok <= token.TILDE; tok++ {\n",
      "note": "Every token is a number, from `ILLEGAL` up to `TILDE`, the last one the package exports. The loop walks all of them; `var words []string` is an empty list to collect into, and lesson 11 is where lists like it are explained."
    },
    {
      "code": "\t\tif tok.IsKeyword() {\n\t\t\twords = append(words, tok.String())\n\t\t}\n\t}\n",
      "note": "**The parser decides what is a keyword, not this program.** `IsKeyword` answers for each token, and `String` gives its spelling."
    },
    {
      "code": "\tfmt.Println(strings.Join(words, \" \"))\n\tfmt.Println(len(words), \"keywords\")\n}\n",
      "note": "One line with the words, one with the count."
    }
  ],
  "output": "break case chan const continue default defer else fallthrough for func go goto if import interface map package range return select struct switch type var\n25 keywords\n"
}
```

Twenty-five. The 2012 talk of section 01 gave the comparison: C99 had 37 and C++11 had 84. Read the
list for what is missing, because **no `class`, `extends`, `try`, `catch`, `throw` or `while`
appears in it.** Those words are not reserved in Go; you could name a variable `class`. And with no `while`, the
one loop is `for`, in the three forms lesson 17 shows.

## No classes and no inheritance

Go has types and methods on them, but no class that bundles the two and no hierarchy where one
type inherits from another. A type is built by putting other types inside it, which is called
composition. Structs are lesson 15, putting one inside another is lesson 16, and methods are
lesson 25. The point to take now is negative: **there is no `extends` and no tree of types to keep
in your head**, so a method you read is defined on the type in front of you or on one visibly
embedded in it.

## No exceptions

A Go function that can fail returns an error as an ordinary value, next to its result, and the
caller looks at it on the next line. There is no `try` around a block and no hidden path by which a
failure jumps out of the middle of a function. `net.LookupHost` in section 02 returned `[127.0.0.1]`
and `<nil>`, and that `<nil>` was the error, printed as a value because nothing went wrong. Lessons
32 to 35 are about errors; lesson 36 covers `panic`, which is for bugs and not for failures.

## No conversion you did not write

Most languages turn an integer into a floating-point number when the two meet in one expression. Go
refuses:

```go
package main

import "fmt"

func main() {
	items := 3
	price := 2.5
	fmt.Println(items * price)
}
```

```
ana@vm:~/why-mix$ go build; echo $?
# example.com/mix
./main.go:8:14: invalid operation: items * price (mismatched types int and float64)
1
```

`items` is an `int` and `price` a `float64`, and **the compiler will not pick a type for you**.
You write the conversion yourself, `float64(items) * price`, and then the rounding and the overflow
are a decision somebody made where a reader can see it. Lesson 10 is about conversions.

The unused import of lesson 4 belongs in this list too. A compile error where other languages give
a warning is the same idea: a choice that costs the next reader is made impossible rather than
discouraged.

## What gets written in it

A small language can be small because nobody uses it. Go is not that case. Some of the best-known
programs that run servers and clusters are written in it, and the module proxy that served the
lab's Go knows them by their module paths:

```
ana@vm:~/why$ go list -m k8s.io/kubernetes@latest github.com/hashicorp/terraform@latest
k8s.io/kubernetes v1.37.1
github.com/hashicorp/terraform v1.16.5
ana@vm:~/why$ go list -m github.com/prometheus/prometheus@latest github.com/docker/docker@latest
github.com/prometheus/prometheus v0.315.0
github.com/docker/docker v28.5.2+incompatible
```

Kubernetes, Terraform, Prometheus and Docker are each published as a Go module, and `go list -m`
printed the latest version of each on the day the lab ran. Lesson 38 explains what a module path
and a version like these are; for now they are the evidence that four programs you may already use
are Go.

::: track devops devsecops
On this track you will operate those programs before you write anything like them. When one of
them misbehaves, the source you end up reading is written in the language this course teaches, and
the binary you end up copying between machines is the single file of section 02.
:::

::: track backend
On this track Go is the language of the services you will write: programs that answer requests over
the network all day, which is the third problem of section 01. The single file of section 02 is what
you will hand to whoever deploys them.
:::

::: track *
Whatever you build with it, the trade is the same: a small language that is quick to read, a
compiler that is quick to run, and one file at the end.
:::
