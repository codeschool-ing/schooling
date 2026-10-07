---
title: An error that is not a failure
version: 1
---

Every error so far meant that something went wrong: a missing file, a bad number, a value out of
range. That makes it natural to read `err != nil` as "it failed". **It means only that the
function had something to say other than the plain result**, and the plainest case where that is
not a failure is the end of the input. This program reads a string four bytes at a time:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"strings\"\n)\n\nfunc main() {\n\tr := strings.NewReader(\"Hello, Go\")\n",
      "note": "`strings.NewReader` turns a string into something with a `Read` method, the same method a file or a network connection has, so the loop below would read either."
    },
    {
      "code": "\tbuf := make([]byte, 4)\n\tfor {\n\t\tn, err := r.Read(buf)\n\t\tfmt.Printf(\"%d %q %v\\n\", n, buf[:n], err)\n",
      "note": "**`Read` fills as much of `buf` as it can and says how many bytes it put there.** The loop prints that count, those bytes and the error before deciding anything, because the bytes come first: a reader may hand over data and an error in the same call."
    },
    {
      "code": "\t\tif err == io.EOF {\n\t\t\tbreak\n\t\t}\n",
      "note": "**`io.EOF` is the reader saying the input is over.** It is the expected way out of the loop, so the program breaks and carries on."
    },
    {
      "code": "\t\tif err != nil {\n\t\t\tfmt.Println(\"read failed:\", err)\n\t\t\treturn\n\t\t}\n\t}\n\tfmt.Println(\"done\")\n}\n",
      "note": "Any other error is a real failure, and only that one is reported as one."
    }
  ],
  "output": "4 \"Hell\" <nil>\n4 \"o, G\" <nil>\n1 \"o\" <nil>\n0 \"\" EOF\ndone\n"
}
```

The third call returned the last byte and `nil`; the fourth returned nothing and `io.EOF`, and the
program printed `done`. Nothing failed. The reader ran out of input, and `io.EOF` is how every
`Read` method in Go says so, from a string like this one to a file or a network connection.

**`io.EOF` is a sentinel: an error kept in a variable so that callers can recognise it by
identity.** Lesson 33 showed why that works. Two errors made by `errors.New` with the same words
are not equal, so a value made once and returned every time is matched by exactly one thing, the
variable that holds it, and never by an unrelated error that happens to share its message.

## The one sentinel compared with `==`

Lesson 34 said to use `errors.Is` rather than `==`, and the loop above wrote `err == io.EOF`. The
documentation of `io.EOF` is why that is allowed here:

```
ana@vm:~/sentinel$ go doc io.EOF
package io // import "io"

var EOF = errors.New("EOF")
    EOF is the error returned by Read when no more input is available. (Read
    must return EOF itself, not an error wrapping EOF, because callers will test
    for EOF using ==.) Functions should return EOF only to signal a graceful
    end of input. If the EOF occurs unexpectedly in a structured data stream,
    the appropriate error is either ErrUnexpectedEOF or some other error giving
    more detail.

```

The parenthesis is a rule for whoever writes a `Read` method, and **it is the rule that makes
`== io.EOF` safe: a reader promises never to wrap it.** A sentinel that comes without that promise
is checked with `errors.Is`, which finds `io.EOF` just as well.

The last two sentences draw a line worth keeping. The end of a stream that was allowed to end is
`io.EOF`. The end of a stream in the middle of something, a file cut off halfway through a record,
is a real failure, and it gets a different error, `io.ErrUnexpectedEOF` or one with more detail,
so that the two are never confused.

A function that reads until the end on your behalf does not pass the sentinel on at all:

```
ana@vm:~/sentinel$ go doc io.ReadAll
package io // import "io"

func ReadAll(r Reader) ([]byte, error)
    ReadAll reads from r until an error or EOF and returns the data it read.
    A successful call returns err == nil, not err == EOF. Because ReadAll is
    defined to read from src until EOF, it does not treat an EOF from Read as an
    error to be reported.

```

**Whether an error is a failure depends on who asked.** To the loop above, the end of the input
was the way out. To `io.ReadAll`, which was asked for everything, reaching the end is success, and
it says `nil`.

## What the standard library declares

`io` declares six sentinels, and `go doc` lists them with the `errors.New` that made each:

```
ana@vm:~/sentinel$ go doc io | grep '^var'
var EOF = errors.New("EOF")
var ErrClosedPipe = errors.New("io: read/write on closed pipe")
var ErrNoProgress = errors.New("multiple Read calls return no data or error")
var ErrShortBuffer = errors.New("short buffer")
var ErrShortWrite = errors.New("short write")
var ErrUnexpectedEOF = errors.New("unexpected EOF")
```

Five of the six are named `Err` followed by what happened, and that is the convention: **a
sentinel's name starts with `Err`**, the way lesson 32's error types end with `Error`. `EOF` is the
exception. Lesson 34 met `fs.ErrNotExist` and its neighbours, section 04 uses `strconv`'s
`ErrSyntax` and `ErrRange`, and section 03 declares one of your own.
