---
title: switch, without the fall-through
version: 1
---

In C, Java and JavaScript a `case` runs on into the next one unless it ends with `break`, and
forgetting the `break` is a classic bug. **In Go a `case` ends by itself.** The program runs the
first case that matches and then leaves the `switch`, with nothing to write. This program, in
`~/cond-switch`, sorts days:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command days says what kind of day each one is.\npackage main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor _, d := range []string{\"mon\", \"sat\", \"fri\", \"sun\", \"xyz\"} {\n\t\tswitch d {\n",
      "note": "`switch d` compares `d` with each case in turn, from the top. The value and the cases have to be of types that can be compared, here all strings."
    },
    {
      "code": "\t\tcase \"sat\", \"sun\":\n\t\t\tfmt.Println(d, \"weekend\")\n",
      "note": "**One case can list several values, separated by commas**, and it matches if any of them does. This is what C programmers write as two cases with the first one left empty to fall through."
    },
    {
      "code": "\t\tcase \"fri\":\n\t\t\tfmt.Println(d, \"almost the weekend\")\n\t\tcase \"mon\", \"tue\", \"wed\", \"thu\":\n\t\t\tfmt.Println(d, \"weekday\")\n",
      "note": "No `break` anywhere. After `\"sat\"` printed `weekend`, the program did not go on into the `\"fri\"` case below it."
    },
    {
      "code": "\t\tdefault:\n\t\t\tfmt.Println(d, \"not a day\")\n\t\t}\n\t}\n}\n",
      "note": "`default` runs only when no case matched, wherever it is written; a `switch` may have one at most, and it is usually written last, where a reader looks for it."
    }
  ],
  "output": "mon weekday\nsat weekend\nfri almost the weekend\nsun weekend\nxyz not a day\n"
}
```

```
ana@vm:~/cond-switch$ go run .
mon weekday
sat weekend
fri almost the weekend
sun weekend
xyz not a day
```

Because each case is a separate choice, the same value in two cases is a mistake, and when the
values are constants the compiler finds it:

```go
	switch d {
	case "sat", "sun":
		fmt.Println(d, "weekend")
	case "fri", "sat":
		fmt.Println(d, "going out")
	}
```

```
ana@vm:~/cond-dup$ go build
# example.com/dup
./main.go:10:14: duplicate case "sat" (constant of type string) in expression switch
	./main.go:8:7: previous case
```

A `break` is still allowed in a case, and lesson 18 showed what it does there: it leaves the
`switch` and nothing else, which inside a loop is almost never what was meant.

## With an initialiser

A `switch` takes a short statement before its value, exactly as an `if` does in section 03, and
the names it declares last until the closing brace. This program, in `~/cond-ext`, names the kind
of a file from its extension:

```go
// Command kind names the kind of each file from its extension.
package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

func main() {
	for _, name := range []string{"main.go", "README.md", "logo.PNG", "Makefile"} {
		switch ext := strings.ToLower(filepath.Ext(name)); ext {
		case ".go":
			fmt.Println(name, "Go source")
		case ".png", ".jpg":
			fmt.Println(name, "image")
		case "":
			fmt.Println(name, "no extension")
		default:
			fmt.Println(name, "something else:", ext)
		}
	}
}
```

```
ana@vm:~/cond-ext$ go run .
main.go Go source
README.md something else: .md
logo.PNG image
Makefile no extension
```

`filepath.Ext` returns the extension with its dot, or an empty string when there is none, and
`strings.ToLower` is why `logo.PNG` matched `".png"`. The `default` case uses `ext`, which no code
after the `switch` could.

## With no value at all

A `switch` with nothing after the keyword compares each case with `true`. **Each case is then a
condition of its own**, and the first one that holds wins, which makes it the tidy way to write a
long `if`, `else if`, `else if` chain. Tidy is not the same as safe, because the first match
wins:

```go
// Command grade turns scores into grades.
package main

import "fmt"

func grade(score int) string {
	switch {
	case score >= 50:
		return "pass"
	case score >= 90:
		return "distinction"
	default:
		return "fail"
	}
}

func main() {
	for _, s := range []int{95, 70, 30} {
		fmt.Println(s, grade(s))
	}
}
```

```
ana@vm:~/cond-grade$ go run .
95 pass
70 pass
30 fail
```

95 is a distinction and got a pass. `score >= 50` was true for it, and it came first, so the
`distinction` case was never tested. Nothing here is a compile error, because the cases are
conditions and the compiler does not compare one with another. With overlapping conditions,
**put the narrowest first**:

```go
	switch {
	case score >= 90:
		return "distinction"
	case score >= 50:
		return "pass"
	default:
		return "fail"
	}
```

```
ana@vm:~/cond-grade$ go run .
95 distinction
70 pass
30 fail
```

## fallthrough, when you mean it

The old behaviour is still available, by name. `fallthrough` as the last statement of a case sends
the program into the body of the next case. **It does not test the next case first**, which is
the part that surprises:

```go
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
		fallthrough
	case n > 100:
		fmt.Println(n, "is more than 100")
	default:
		fmt.Println(n, "is something else")
	}
}
```

```
ana@vm:~/cond-fall$ go run .
5 is more than 3
5 is more than 100
```

The program printed that 5 is more than 100. `n > 100` was never evaluated: `fallthrough` ran the
body under it whatever it said, and then stopped, because that body had no `fallthrough` of its
own. A `fallthrough` in the last case has nowhere to go, and is refused:

```go
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
	default:
		fmt.Println(n, "is something else")
		fallthrough
	}
}
```

```
ana@vm:~/cond-fall$ go build
# example.com/fall
./main.go:12:3: cannot fallthrough final case in switch
```

It is also refused anywhere but as the last statement of a case, and in the type switch of
lesson 29. In Go's own source it is rare, counted the way lesson 18 counted `goto`:

```
ana@vm:~/cond-fall$ grep -rE --include=*.go '^\s*switch\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
6471
ana@vm:~/cond-fall$ grep -rE --include=*.go '^\s*fallthrough\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
234
```

234 against 6,471 switches, about one in twenty-eight, and a case list or a reordering is
nearly always the clearer fix. When a case should share another's work, list both values in one
case, as `"sat", "sun"` did, or move the shared work into a function both cases call.
