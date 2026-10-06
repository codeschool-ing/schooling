---
title: Named results and the bare return
version: 1
---

`divmod` returned `(int, int)`, and nothing in that signature says which `int` is the quotient. A
function's results can carry names, exactly as its parameters do, and the standard library uses
them where the types alone would leave a reader guessing:

```
ana@vm:~/funcs-multi$ go doc strings.Cut
package strings // import "strings"

func Cut(s, sep string) (before, after string, found bool)
    Cut slices s around the first instance of sep, returning the text before and
    after sep. The found result reports whether sep appears in s. If sep does
    not appear in s, cut returns s, "", false.

```

`(before, after string, found bool)` is three results, grouped the way parameters are, and the
names do the work of a sentence: two strings, the part before the separator and the part after,
and whether it was found. With `(string, string, bool)` you would have to read the comment to know
the order. `Println` in lesson 4 had the same kind of signature, `(n int, err error)`.

## What a name gives a result

**A named result is a variable, declared when the function starts and set to its zero value.**
The function body can assign to it like any other variable, and a `return` with nothing after it,
a **bare return**, hands back whatever the named results hold at that moment:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\nfunc nothing() (n int, s string, err error) {\n\treturn\n}\n",
      "note": "**Nothing is assigned, and the bare `return` still returns three values**: the zero of each type, from lesson 6. The results exist from the first line of the function."
    },
    {
      "code": "\nfunc setting(line string) (key, value string, ok bool) {\n\tkey, value, ok = strings.Cut(line, \"=\")\n",
      "note": "`key`, `value` and `ok` are already declared, so the assignment is `=`, not `:=`. `strings.Cut` fills all three at once."
    },
    {
      "code": "\tkey = strings.TrimSpace(key)\n\tvalue = strings.TrimSpace(value)\n\treturn\n}\n",
      "note": "The results are changed in place, and the bare `return` hands back their values as they are now: trimmed of the spaces around `=`."
    },
    {
      "code": "\nfunc main() {\n\tn, s, err := nothing()\n\tfmt.Printf(\"%d %q %v\\n\", n, s, err)\n\tfmt.Println(setting(\"port = 8080\"))\n\tfmt.Println(setting(\"verbose\"))\n}\n",
      "note": "The caller sees no difference. The names belong to the function; outside it, `setting` returns three values like any other function does."
    }
  ],
  "output": "0 \"\" <nil>\nport 8080 true\nverbose  false"
}
```

The last line has two spaces in it on purpose. `"verbose"` has no `=`, so `strings.Cut` returned
the whole line as `before`, an empty `after` and `false`, as its documentation said, and
`Println` put a space either side of the empty string.

## When the names hurt

The bare return reads well in a function of five lines, where the results are visible on the
screen. In a function of forty lines it does not: a reader who reaches `return` has to scroll up
to learn what it returns, and then search the body for the last assignment to each name.

It also meets shadowing, the bug lesson 6 described, and the compiler catches only part of it. Here
`:=` inside the `if` declares a new `n` and a new `err`, and the bare return is inside that block:

```go
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
```

```
ana@vm:~/funcs-shadow$ go run .
# example.com/funcs-shadow
./main.go:12:4: result parameter n not in scope at return
	./main.go:10:3: inner declaration of var n int
./main.go:12:4: result parameter err not in scope at return
	./main.go:10:6: inner declaration of var err error
```

The `return` on line 12 would hand back the outer `n` and `err`, which were never assigned, while
the values the function just computed sit in the inner ones. **The compiler refuses a bare return
when a named result is hidden by another variable of the same name.** That catches one return and
not the bug. Write the inner one out in full, as `return n, err`, and the compiler is satisfied,
because you said which `n` you meant:

```go
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return n, err
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
```

```
ana@vm:~/funcs-shadow2$ go vet && go run .
parsed 8080
0 <nil>
```

`go vet` has nothing to say, the function parsed 8080, and the caller received 0. The bare
`return` at the bottom is outside the `if`, where nothing hides the results, so it hands back the
outer `n` and `err` that nobody assigned. **The fix is `=` instead of `:=`**, so the `if` assigns
to the results instead of declaring new variables beside them.

So the habit most Go code follows is short to state. **Name results when the names document
something**, as in `strings.Cut`, and use a bare return only in a function short enough to read at
a glance. Names you add for documentation do not oblige you to use the bare form; `return before,
after, true` is fine in a function with named results.

## The one thing only a name can do

A named result is a variable that still exists after the `return` statement has run, and one Go
feature reaches it there. `defer` schedules a call to run when the function returns, and a
deferred function can change a named result on the way out:

```go
package main

import "fmt"

func answer() (n int) {
	defer func() {
		n++
	}()
	return 41
}

func main() {
	fmt.Println(answer())
}
```

```
ana@vm:~/funcs-defer$ go run .
42
```

`return 41` sets `n` to 41. Then the deferred function runs, adds one to `n`, and only after that
does the caller receive `n`, now 42. With an unnamed `(int)` result there would be no name for the
deferred function to change. The `func() { … }()` written inside `answer` is a function literal,
which lesson 21 explains. `defer` itself, and the real use of this pattern, turning a panic into an
`error` before it leaves a function, are lesson 36's.
