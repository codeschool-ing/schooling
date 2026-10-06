---
title: "defer: the calls that run on the way out"
version: 1
---

`defer` puts a function call aside and runs it when the surrounding function returns. The picture
many people bring is Python's `with` or C#'s `using`, where the cleanup happens at the end of a
block. **A deferred call runs when the function returns, not when the block ends**, and the
difference shows the moment a `defer` sits inside a loop. `~/panic-defer` puts five calls aside and
prints in between:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command defer shows when deferred calls run, and in what order.\npackage main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor i := range 3 {\n\t\tdefer fmt.Println(\"deferred in the loop:\", i)\n\t}\n",
      "note": "**Three calls put aside, one per turn of the loop.** None of them runs here: each `defer` records the call with its argument, `i`, as it is at that moment."
    },
    {
      "code": "\n\tx := 1\n\tdefer fmt.Println(\"x when deferred:\", x)\n",
      "note": "**The arguments are read now.** `x` is 1 at this line, so 1 is what this call will print, whatever happens to `x` afterwards."
    },
    {
      "code": "\tdefer func() {\n\t\tfmt.Println(\"x when run:\", x)\n\t}()\n\tx = 2\n",
      "note": "A function literal with no arguments, deferred. It reads `x` when it runs rather than now, because a closure holds the variable itself (lesson 21). Then `x` becomes 2."
    },
    {
      "code": "\n\tfmt.Println(\"end of main\")\n}\n",
      "note": "The last line of `main`. When `main` returns, the five deferred calls run, the most recent first."
    }
  ],
  "output": "end of main\nx when run: 2\nx when deferred: 1\ndeferred in the loop: 2\ndeferred in the loop: 1\ndeferred in the loop: 0\n"
}
```

Three rules, and the output shows each of them.

**Deferred calls run last in, first out.** The closure was deferred last and ran first; the loop's
three calls were deferred first and ran last, from 2 down to 0. Cleanup usually undoes things in the
reverse order they were set up, and this order does that without anybody arranging it.

**They wait for the function, not the block.** The loop finished, `end of main` was printed, and
only then did the three calls from inside the loop run. A `defer` in a loop that runs a thousand
times holds a thousand calls until the function returns.

**The arguments are evaluated at the `defer` line.** `fmt.Println("x when deferred:", x)` was put
aside with `x` already read as 1, and the later `x = 2` did not reach it. The function literal took
no arguments. It reads `x` when it runs, and by then `x` was 2: it captured the variable, as lesson
21 showed closures do.

## `defer f.Close()`

The use you will write most often is closing something on every way out of a function. `countLines`
in `~/panic-close` opens a file, counts its lines with a `bufio.Scanner`, and returns:

```go
func countLines(name string) (int, error) {
	f, err := os.Open(name)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	n := 0
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

func main() {
	for _, name := range os.Args[1:] {
		n, err := countLines(name)
		if err != nil {
			fmt.Println(err)
			continue
		}
		fmt.Println(name, n)
	}
}
```

```
ana@vm:~/panic-close$ go build && ./lines notes.txt missing.txt
notes.txt 3
open missing.txt: no such file or directory
```

**`defer f.Close()` goes on the line after the error check**, so the call that closes the file sits
next to the call that opened it, and nobody has to remember it at each `return` below. Before the
check, `f` might not be a file at all; `missing.txt` returned at the first `return`, with nothing
open and nothing deferred.

The loop in `main` is the reason `countLines` is a function of its own. Written inline, with
`defer f.Close()` inside the `for`, every file would stay open until `main` returned: the second
rule above.

A deferred call's results go nowhere, so `defer f.Close()` drops the `error` that `Close` returns.
For a file the program only read, nothing is lost. When the program wrote the file, call `Close`
yourself at the end and check its error like any other.

## When a panic passes through

Deferred calls run however the function ends, and a panic is one of the ways. `~/panic-exit` defers
one line and then stops in one of two ways, a write to a nil map or `os.Exit`:

```go
func main() {
	defer fmt.Println("deferred: cleaning up")
	if len(os.Args) > 1 {
		os.Exit(3)
	}
	var prices map[string]int
	prices["pear"] = 3
}
```

```
ana@vm:~/panic-exit$ go build && ./exit; echo $?
deferred: cleaning up
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/panic-exit/main.go:15 +0x7f
2
ana@vm:~/panic-exit$ ./exit now; echo $?
3
```

The deferred line came out **before** the panic message. **A panic runs the deferred calls of each
function it leaves, and only then stops the program.** That is the opening section 04 uses: a
deferred function is the one place code still runs while a panic is on its way out.

`os.Exit` is different. With an argument the program exited with 3 and printed nothing, and its
documentation says why in one sentence:

```
ana@vm:~/panic-exit$ go doc os.Exit
package os // import "os"

func Exit(code int)
    Exit causes the current program to exit with the given status code.
    Conventionally, code zero indicates success, non-zero an error. The program
    terminates immediately; deferred functions are not run.

    For portability, the status code should be in the range [0, 125].

```

`log.Fatal` ends the same way, which is easy to miss because its name is about logging:

```
ana@vm:~/panic-exit$ go doc log.Fatal
package log // import "log"

func Fatal(v ...any)
    Fatal is equivalent to Print followed by a call to os.Exit(1).

```

**`os.Exit` and `log.Fatal` skip every deferred call in the program.** Call them from `main`, once
the work that needed cleaning up is done, and never from deep inside a function that has deferred
something. Lesson 20 showed a deferred function changing a named result on the way out; section 04
puts that together with this section to turn a panic into an `error`.
