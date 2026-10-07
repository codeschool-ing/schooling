---
title: fmt.Errorf, context, and the wrapping verb
version: 1
---

`fmt.Errorf` is `Printf` that returns an `error` instead of printing: the same format string, the
same verbs, and the result is an error whose message is the formatted text. Section 04 uses it for
`age -4 is negative`, a message with a value in it. Its bigger job is the one this section is
about, which is **adding context to an error on its way up**.

Lesson 32 passed errors up as they came, and for one call that is fine. In a program of any size
it is not. `os.ReadFile` reports `open settings.json: no such file or directory` and nothing else,
because it cannot know who asked: whether the server was starting, a test was loading a fixture or
a user had typed the name. **Each function that returns an error knows one thing the error does
not, what it was doing**, and it adds that before returning.

## %v and %w: the same text, two different values

There are two verbs for putting an error into a new message. `%v` is the verb `Printf` already
uses for any value. `%w` exists only in `fmt.Errorf`. In `~/wrap-verbs`, the same words added both
ways:

```go
// Command verbs adds the same words to an error with %v and with %w.
package main

import (
	"fmt"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	v := fmt.Errorf("read config: %v", err)
	w := fmt.Errorf("read config: %w", err)
	fmt.Println(v)
	fmt.Println(w)
	fmt.Printf("%T\n%T\n", v, w)
}
```

```
ana@vm:~/wrap-verbs$ go run .
read config: open settings.json: no such file or directory
read config: open settings.json: no such file or directory
*errors.errorString
*fmt.wrapError
```

The two messages are byte for byte the same; the two types are not. With `%v`, `fmt.Errorf` turned
everything into text and returned the `*errors.errorString` of section 02, the same thing
`errors.New` would have built from that text. With `%w` it returned a `*fmt.wrapError`. The source
of `fmt.Errorf` says what the difference is:

```
ana@vm:~/wrap-verbs$ sed -n '44,50p;70,73p' /usr/local/go/src/fmt/errors.go
	switch len(p.wrappedErrs) {
	case 0:
		err = errors.New(s)
	case 1:
		w := &wrapError{msg: s}
		w.err, _ = a[p.wrappedErrs[0]].(error)
		err = w
type wrapError struct {
	msg string
	err error
}
```

No `%w` in the format, `case 0`, and the result is `errors.New` of the text. One `%w`, `case 1`,
and the result is a struct with two fields: the message, and `err`, **the original error, kept
whole inside the new one**. That is what wrapping means. `%v` copies the old error's words and
drops the error; `%w` copies the words and keeps the error. Code that wants to look inside a
wrapped error, to ask whether a file was missing or which path failed, can reach the
`*fs.PathError` in `w` and has nothing to reach in `v`. Lesson 34 does the reaching.

## Three layers, one message

A real program wraps at every layer that has something to add. `~/wrap-context` is a server that
cannot find its configuration:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command server fails to start, and says why.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n)\n\nfunc readConfig(path string) ([]byte, error) {\n\tdata, err := os.ReadFile(path)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"read config: %w\", err)\n\t}\n\treturn data, nil\n}\n",
      "note": "**The lowest layer says what it was doing when the call failed**, `read config`, and wraps the error `os.ReadFile` returned. It does not repeat the file's name: the `*fs.PathError` underneath already carries it."
    },
    {
      "code": "\nfunc start() error {\n\tif _, err := readConfig(\"settings.json\"); err != nil {\n\t\treturn fmt.Errorf(\"start server: %w\", err)\n\t}\n\treturn nil\n}\n",
      "note": "**The next layer up does the same with its own step**, `start server`. It knows nothing about files; it knows that it was starting a server and that reading the configuration was part of that. The `if` with an initialiser is lesson 19's."
    },
    {
      "code": "\nfunc main() {\n\tif err := start(); err != nil {\n\t\tfmt.Println(err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "`main` adds nothing and prints what arrived. It is the top of the program, the one place that reports instead of returning."
    }
  ]
}
```

```
ana@vm:~/wrap-context$ go run .
start server: read config: open settings.json: no such file or directory
exit status 1
```

`exit status 1` is `go run` reporting the program's own exit status, the `os.Exit(1)` in `main`.
The line above it is one message, and three functions wrote it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"The message start server: read config: open settings.json: no such file or directory, divided into the three parts that three functions wrote. os.ReadFile wrote the last part first: open settings.json: no such file or directory. readConfig then put read config: in front of it, and start put start server: in front of that. Written from the cause outwards, the message is read from left to right: what the program was doing, then what that needed, then why it failed.\"><defs><marker id=\"ml-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ml-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"119\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">start server: </text><path d=\"M119 62 L119 68 L204.8 68 L204.8 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M161.9 34 L161.9 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"161.9\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. start adds</text><text x=\"211.39999999999998\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">read config: </text><path d=\"M211.39999999999998 62 L211.39999999999998 68 L290.59999999999997 68 L290.59999999999997 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250.99999999999997\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. readConfig adds</text><text x=\"297.2\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open settings.json: no such file or directory</text><path d=\"M297.2 62 L297.2 68 L594.2 68 L594.2 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"445.7\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1. os.ReadFile writes</text><path d=\"M588.2 114 L125 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ml-wire)\"></path><text x=\"356.6\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written from the cause outwards</text><path d=\"M125 154 L588.2 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ml-phosphor)\"></path><text x=\"356.6\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read left to right: what the program was doing, down to why it failed</text></svg>", "caption": "One message, written by three functions. Each layer puts its own words in front of the error it received, so the cause ends up last and the message reads from the outside in."}
```

Each layer wrote its words in front of the error it received, so the cause, written first, ends up
last. **A wrapped message reads left to right from what the program was doing down to why it
failed**, and every colon is a step deeper. Nobody had to plan the sentence; it fell out of each
function saying one thing.

## Lower case, no full stop, no "failed"

That only works if every layer writes a fragment that can sit in the middle of a sentence. Here is
`~/wrap-style`, the same program with the two calls written as sentences of their own:
`"Error: could not read config: %w."` in `readConfig` and `"Failed to start server: %w."` in
`start`.

```
ana@vm:~/wrap-style$ go run .
Failed to start server: Error: could not read config: open settings.json: no such file or directory..
exit status 1
```

A capital letter in the middle of the line, `Error:` saying what everybody already knew, and two
full stops at the end where two layers each closed a sentence. The conventions that avoid this are
the ones the standard library keeps: **a message starts with a lower-case letter, ends without
punctuation, and says what was being done rather than that it failed.** Counted over the calls to
`errors.New` in `/usr/local/go/src`, tests left out:

```
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("' /usr/local/go/src | grep -vc -e _test.go -e testdata
2095
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("[A-Z]' /usr/local/go/src | grep -vc -e _test.go -e testdata
81
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("[^"]*\."\)' /usr/local/go/src | grep -vc -e _test.go -e testdata
2
```

Of 2,095 messages, 81 start with a capital, and nearly all of those start with the name of a type,
a function or an acronym, `Time`, `Rat`, `P256`, `JSON`, which keeps its capital wherever it
stands. Two end with a full stop.

## %w wants an error

`%w` takes an error and nothing else. Handed a string, `fmt.Errorf` does not refuse; it prints its
complaint into the message, as `Printf` did with the wrong verb in lesson 4:

```go
package main

import "fmt"

func main() {
	reason := "disk full"
	err := fmt.Errorf("save notes: %w", reason)
	fmt.Println(err)
}
```

```
ana@vm:~/wrap-vet$ go run .
save notes: %!w(string=disk full)
ana@vm:~/wrap-vet$ go vet
main.go:7:33: fmt.Errorf format %w has arg reason of wrong type string
```

The compiler accepts it, because the format is a string to it. `go vet` reads the format and the
arguments together and catches it, which is one more reason to run it before anyone reads the code.
