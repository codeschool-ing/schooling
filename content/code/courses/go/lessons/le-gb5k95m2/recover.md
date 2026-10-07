---
title: recover, and the two places it belongs
version: 1
---

`recover` is the one way to stop a panic, and the tempting reading is that it is Go's `catch`: wrap
it around anything risky and carry on. **It is not a `catch`, and it is not meant to be used like
one.** It works in one position only, it does not resume the code that panicked, and the places
it belongs come down to two. Its documentation states the position:

```
ana@vm:~/panic-sum$ go doc builtin.recover
package builtin // import "builtin"

func recover() any
    The recover built-in function allows a program to manage behavior of
    a panicking goroutine. Executing a call to recover inside a deferred
    function (but not any function called by it) stops the panicking sequence
    by restoring normal execution and retrieves the error value passed to the
    call of panic. If recover is called outside the deferred function it will
    not stop a panicking sequence. In this case, or when the goroutine is not
    panicking, recover returns nil.

    Prior to Go 1.21, recover would also return nil if panic is called with a
    nil argument. See [panic] for details.

```

**`recover` stops a panic only when a deferred function calls it directly.** Section 03 showed why
that is the place: while a panic is on its way out, deferred calls are the only code that still
runs. Anywhere else `recover` returns `nil` and does nothing. When it does stop a panic it returns
the value that was passed to `panic`, and the function that deferred it then returns to its caller
as if nothing had happened. The rest of that function, after the line that panicked, never runs.

## Inside a package: panic to climb out, an error at the door

The first place is a package that panics on purpose, inside itself, to get out of code nested many
calls deep, and turns the panic back into an `error` before it reaches anybody who called it. Here
it is at the smallest size that shows the shape. `Sum` in `~/panic-sum` adds the numbers in a text
like `"1+2+3"`, and its helper `number` gives up through a panic instead of returning an error:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command sum adds the numbers in a text like \"1+2+3\".\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n\t\"strings\"\n)\n\n// parseError carries a failure out of the helpers. It never leaves Sum.\ntype parseError struct {\n\terr error\n}\n",
      "note": "**A type of the package's own, used for nothing but its panics.** It holds an ordinary `error`. Because nobody outside the package can make one, a `parseError` that reaches the recover below can only have come from `fail`."
    },
    {
      "code": "\nfunc fail(format string, args ...any) {\n\tpanic(parseError{fmt.Errorf(format, args...)})\n}\n",
      "note": "**`fail` builds an error and panics with it, wrapped in `parseError`.** Wherever a helper calls it, the helper stops there, and so does every function between it and `Sum`."
    },
    {
      "code": "\nfunc number(s string) int {\n\tif s == \"\" {\n\t\tfail(\"empty term\")\n\t}\n\tn, err := strconv.Atoi(s)\n\tif err != nil {\n\t\tfail(\"%q is not a number\", s)\n\t}\n\treturn n\n}\n",
      "note": "A helper that returns only the number. Its two failures leave through `fail`, so its signature carries no `error`, and neither would the signatures of the helpers that called it in a bigger parser."
    },
    {
      "code": "\n// Sum answers with an error, never with a panic.\nfunc Sum(text string) (total int, err error) {\n\tdefer func() {\n\t\tr := recover()\n\t\tif r == nil {\n\t\t\treturn\n\t\t}\n\t\tpe, ok := r.(parseError)\n\t\tif !ok {\n\t\t\tpanic(r)\n\t\t}\n\t\ttotal, err = 0, pe.err\n\t}()\n",
      "note": "**The door, and the recover that guards it.** `recover()` returns `nil` when nothing panicked. Otherwise the type assertion of lesson 29 asks whether the value is a `parseError`: if not, it is somebody's bug and goes on panicking; if so, the named results become `0` and the error inside."
    },
    {
      "code": "\tfor _, term := range strings.Split(text, \"+\") {\n\t\ttotal += number(term)\n\t}\n\treturn total, nil\n}\n",
      "note": "The work itself, written as if nothing could fail. `strings.Split` cuts the text at each `+`, so `\"1++3\"` gives an empty term in the middle."
    },
    {
      "code": "\nfunc main() {\n\tfor _, text := range []string{\"1+2+3\", \"1++3\", \"1+two\"} {\n\t\tfmt.Println(Sum(text))\n\t}\n}\n",
      "note": "Three texts, one good and two bad. `fmt.Println(Sum(text))` passes both results of `Sum` straight to `Println`."
    }
  ],
  "output": "6 <nil>\n0 empty term\n0 \"two\" is not a number\n"
}
```

Read the three calls as the figure draws the second one. `number("")` called `fail`, `fail`
panicked, and the panic left `number`, which had deferred nothing, and reached `Sum`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The panic in ~/panic-sum climbing the calls. main calls Sum, which calls number with an empty term. number calls fail, which panics with a parseError. number has no deferred calls, so the panic leaves it and climbs to Sum. Sum&#x27;s deferred function calls recover, which stops the panic and returns the parseError; the function sets total to 0 and err to the error, and Sum returns normally to main, which receives 0 and an error and carries on.\"><defs><marker id=\"rc-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"rc-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"rc-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"24\" width=\"300\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main()</text><text x=\"56\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fmt.Println(Sum(&quot;1++3&quot;))</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Sum(&quot;1++3&quot;)</text><rect x=\"56\" y=\"146\" width=\"266\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">defer func() { recover() ... }</text><rect x=\"40\" y=\"228\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">number(&quot;&quot;)</text><text x=\"56\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">fail(&quot;empty term&quot;)</text><path d=\"M90 80 L90 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-wire)\"></path><path d=\"M90 200 L90 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-wire)\"></path><text x=\"100\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><text x=\"100\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><path d=\"M340 254 H360 V166 H324\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rc-amber)\"></path><text x=\"366\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">panic</text><path d=\"M260 108 L260 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-phosphor)\"></path><text x=\"270\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">returns</text><text x=\"420\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main carries on</text><text x=\"420\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">it receives 0 and an error, and no panic</text><text x=\"420\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">recover stops the panic</text><text x=\"420\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the deferred function sets total and err,</text><text x=\"420\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and Sum returns to its caller</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">fail panics with a parseError</text><text x=\"420\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">number defers nothing, so the panic</text><text x=\"420\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leaves it and climbs to Sum</text></svg>", "caption": "A panic climbs through the calls until a deferred recover stops it. The function that deferred the recover returns normally, with whatever its named results hold."}
```

**The function whose deferred call recovers returns normally, with whatever its named results hold.** That is the
pattern lesson 20 promised, a deferred function changing a named result on the way out, put to its
real use: the panic went in at one end of `Sum` and an ordinary `error` came out at the other. `Sum`
is in package `main` here only to keep the example in one file; in a real program it would be the exported
function of a package of its own, with `parseError`, `fail` and `number` unexported, which lesson 39
explains.

With two levels of calls, returning an error from `number` would have been simpler, and that is the
right choice for code this small. The pattern pays in a parser, where the helper that finds the
mistake can sit ten calls below the function the caller called, and every level in between would
otherwise need its own `if err != nil`.

### The check that keeps it honest

The deferred function recovers only its own `parseError`, and panics again with anything else. That
line looks fussy until somebody adds a bug. `~/panic-sumbug` adds a rule against negative numbers,
and puts its check first in `number`:

```go
func number(s string) int {
	if s[0] == '-' {
		fail("%s: negative numbers are not allowed", s)
	}
	if s == "" {
		fail("empty term")
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		fail("%q is not a number", s)
	}
	return n
}
```

```
ana@vm:~/panic-sumbug$ go build && ./sum 2>&1 | head -2
6 <nil>
panic: runtime error: index out of range [0] with length 0 [recovered, repanicked]
ana@vm:~/panic-sumbug$ ./sum >/dev/null 2>&1; echo $?
2
```

The empty term in `"1++3"` reached `s[0]` before the check for `""`, the order mistake lesson 8
showed with `&&`. That is a runtime error, not a `parseError`, so the deferred function panicked
again, and the message says so: `[recovered, repanicked]`. **A recover that kept every panic would
have reported this bug as bad input**, the caller would have shown the user a parsing error, and the
index out of range would never have reached a trace anybody reads.

The standard library writes the same rule down in `encoding/gob`, which encodes and decodes Go
values this way:

```
ana@vm:~/panic-sum$ sed -n 9,14p $(go env GOROOT)/src/encoding/gob/error.go
// Errors in decoding and encoding are handled using panic and recover.
// Panics caused by user error (that is, everything except run-time panics
// such as "index out of bounds" errors) do not leave the file that caused
// them, but are instead turned into plain error returns. Encoding and
// decoding functions and methods that do not return an error either use
// panic to report an error or are guaranteed error-free.
```

The template parser in `text/template/parse` does the same, and so did `encoding/json` until Go
1.27. Its `encode.go` still has the deferred recover, with the same type check and the same
`panic(r)` for anything that is not its own:

```
ana@vm:~/panic-sum$ grep -n -A10 '^func (e \*encodeState) marshal' $(go env GOROOT)/src/encoding/json/encode.go
332:func (e *encodeState) marshal(v any, opts encOpts) (err error) {
333-	defer func() {
334-		if r := recover(); r != nil {
335-			if je, ok := r.(jsonError); ok {
336-				err = je.error
337-			} else {
338-				panic(r)
339-			}
340-		}
341-	}()
342-	e.reflectValue(reflect.ValueOf(v), opts)
```

That file is no longer part of the package as go1.27.1 builds it, though. `go list` names the files
a build compiles, so it can compare three builds of `encoding/json`: go1.27.1 as it comes, go1.27.1
with the `jsonv2` experiment switched off, and the go1.26.0 toolchain from lesson 2:

```
ana@vm:~/panic-sum$ go list -f '{{.GoFiles}}' encoding/json
[v2_decode.go v2_encode.go v2_indent.go v2_inject.go v2_options.go v2_scanner.go v2_stream.go]
ana@vm:~/panic-sum$ GOEXPERIMENT=nojsonv2 go list -f '{{.GoFiles}}' encoding/json
[decode.go encode.go fold.go indent.go scanner.go stream.go tables.go tags.go]
ana@vm:~/panic-sum$ cd ~ && GOTOOLCHAIN=go1.26.0 go list -f '{{.GoFiles}}' encoding/json
[decode.go encode.go fold.go indent.go scanner.go stream.go tables.go tags.go]
```

The last command runs from `~` because this module's `go.mod` asks for 1.27.1. In go1.27.1
`encoding/json` is built from the `v2_` files, which run on the code of `encoding/json/v2`, the
package lesson 15 compared it with; the old files, `encode.go` among them, are what go1.26.0 built
and what the experiment switch still selects. The pattern did not go anywhere. One package stopped
needing it.

## At a boundary: one bad request

The second place is the edge of a program that serves many independent requests, where one of them
going wrong must not take the others down. Go's HTTP server is the standard instance, and its
documentation says what it does:

```
ana@vm:~/panic-http$ go doc net/http.Handler | sed -n 21,26p
    If ServeHTTP panics, the server (the caller of ServeHTTP) assumes that the
    effect of the panic was isolated to the active request. It recovers the
    panic, logs a stack trace to the server error log, and either closes the
    network connection or sends an HTTP/2 RST_STREAM, depending on the HTTP
    protocol. To abort a handler so the client sees an interrupted response but
    the server doesn't log an error, panic with the value ErrAbortHandler.
```

`~/panic-http` serves two paths, and the handler for `/boom` writes to a nil map, the bug from
section 03:

```go
// Command panic-http answers on two paths, and one of them has a bug.
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	log.SetFlags(0) // no date on each line
	http.HandleFunc("/ok", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	http.HandleFunc("/boom", func(w http.ResponseWriter, r *http.Request) {
		var hits map[string]int
		hits[r.URL.Path]++
		fmt.Fprintln(w, "never sent")
	})
	log.Fatal(http.ListenAndServe("localhost:8036", nil))
}
```

Each `HandleFunc` names a path and the function that answers it, and `ListenAndServe` answers
requests until the program is stopped. The server starts in the background with its log going to
`server.log`, and `curl` asks it for both paths:

```
ana@vm:~/panic-http$ go build && (./panic-http 2>server.log &)
ana@vm:~/panic-http$ curl -sS --local-port 41036 localhost:8036/boom
curl: (52) Empty reply from server
ana@vm:~/panic-http$ curl -s localhost:8036/ok
ok
ana@vm:~/panic-http$ head -1 server.log
http: panic serving 127.0.0.1:41036: assignment to entry in nil map
ana@vm:~/panic-http$ grep panic-http/main.go server.log
	/home/ana/panic-http/main.go:17 +0x36
```

The request to `/boom` got no answer: the server closed that connection, and `curl` said so. The
next request was answered as if nothing had happened. The log names the client by address and port, the
panic's message and, further down the stack trace, the line of the bug, `main.go:17`. The
`--local-port` option only fixes `curl`'s port, so that the line reads the same every time this
lesson is recorded. **One
request failed and the server did not.** Without the recover in `net/http`, the nil map would have
ended the process and every request in flight with it.

That is still a bug, and the log line is the report of it. A recover at a boundary keeps the program
serving while somebody reads the trace, which is lesson 37's subject; it does not make the handler
right. A program of your own with the same shape, a loop that takes jobs one at a time, puts its
recover in the same place: around one job, logging what it caught.

## What `recover` cannot catch

**A recover protects only the goroutine it runs in.** A goroutine is a function running on its own,
started with the keyword `go`; they are the `go-concurrency` course's subject, and one is enough
here. `~/panic-goroutine` defers a recover in `main` and starts a goroutine that panics, then
sleeps for a tenth of a second so the goroutine has time to run:

```go
// Command goroutine panics somewhere its recover cannot reach.
package main

import (
	"fmt"
	"time"
)

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	go func() {
		panic("in another goroutine")
	}()
	time.Sleep(100 * time.Millisecond)
	fmt.Println("never printed")
}
```

```
ana@vm:~/panic-goroutine$ go build && ./goroutine 2>/dev/null; echo $?
2
ana@vm:~/panic-goroutine$ ./goroutine 2>&1 | grep -E '^(panic|created by)'
panic: in another goroutine
created by main.main in goroutine 1
```

Nothing reached standard output: not `recovered:` and not `never printed`. The panic belonged to
the goroutine `main` had started, its own deferred calls were the only ones that ran, there were
none, and the whole program stopped with status 2. This is why `net/http` recovers where it does:
the server runs each connection on a goroutine of its own, and the deferred recover is inside that
goroutine's function, `(*conn).serve`, not around the server.

**A fatal error is not a panic, and nothing recovers it.** `~/panic-overflow` calls a function that
calls itself forever:

```go
// Command overflow calls itself until the stack runs out.
package main

import "fmt"

func depth(n int) int {
	return depth(n+1) + 1
}

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	fmt.Println(depth(0))
}
```

```
ana@vm:~/panic-overflow$ go build && ./overflow 2>&1 | grep -E '^(runtime: goroutine|fatal error)'
runtime: goroutine stack exceeds 1000000000-byte limit
fatal error: stack overflow
ana@vm:~/panic-overflow$ ./overflow >/dev/null 2>&1; echo $?
2
```

The goroutine's stack reached the runtime's limit of a thousand million bytes, the runtime printed
`fatal error` and stopped the program, and the deferred function never ran. Running out of memory
ends a program the same way, and so do two goroutines writing one map at once, which the
`go-concurrency` course shows. `os.Exit`, from section 03, is a third way out that no recover sees,
because it is not a panic at all.

So the places are two, and both are deliberate: **inside a package, around the panics it throws
itself, and at the boundary of one request or one job.** A `recover` anywhere else turns a bug into
a program that keeps running in a state nobody intended, which is worse than the crash it
prevented.
