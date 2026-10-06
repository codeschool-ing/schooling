---
title: break and continue
version: 1
---

A loop in Go stops when its condition turns false or its `range` runs out, which are the forms of
lesson 17. Two statements end things sooner. **`break` ends the whole loop; `continue` ends only
the current turn**, and the loop carries on with the next one. This program, in `~/flow`, uses
both:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command total adds up the numbers in a list of lines, up to the line \"end\".\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n)\n\nfunc main() {\n\tlines := []string{\"12\", \"\", \"7\", \"seven\", \"end\", \"40\"}\n\tsum := 0\n\tfor _, line := range lines {\n",
      "note": "Six lines of input, as a program might read them from a file. Only two of them are numbers that should count: the `40` comes after the end marker."
    },
    {
      "code": "\t\tif line == \"end\" {\n\t\t\tbreak\n\t\t}\n",
      "note": "**`break` leaves the `for`, not the `if` it is written in.** An `if` is not something you leave; the `break` belongs to the nearest loop around it, and the program goes on after that loop's closing brace."
    },
    {
      "code": "\t\tn, err := strconv.Atoi(line)\n\t\tif err != nil {\n\t\t\tfmt.Printf(\"skipping %q\\n\", line)\n\t\t\tcontinue\n\t\t}\n\t\tsum += n\n\t}\n",
      "note": "`strconv.Atoi` from lesson 10 returns an error for anything that is not a whole number. **`continue` skips the rest of this turn**, so `sum += n` never sees a line that failed, and the loop moves on to the next line."
    },
    {
      "code": "\tfmt.Println(\"sum:\", sum)\n}\n",
      "note": "Where `break` lands: the first statement after the loop."
    }
  ],
  "output": "skipping \"\"\nskipping \"seven\"\nsum: 19\n"
}
```

```
ana@vm:~/flow$ go run .
skipping ""
skipping "seven"
sum: 19
```

12 and 7 make 19. The empty line and `"seven"` were skipped one turn at a time, and `40` was never
read, because the loop had ended at `"end"`.

Both statements keep the body of a loop flat. Without `continue`, the rest of the body would sit
inside an `else`, and every new check would push it one level further right. With it, each
reason to skip a line is one `if` that ends early, and the work the loop is for stays at the left
margin, where a reader finds it.

## What continue skips, and what it does not

Where the next turn starts depends on which form of `for` you wrote. In the three-clause form,
the post statement, the `i++`, belongs to the loop rather than to the body, so `continue` still
runs it. In the form with only a condition, the increment is an ordinary line of the body, and
**`continue` skips it like any other line**. Here is the same loop written both ways, in
`~/flow-skip`:

```go
package main

import "fmt"

func main() {
	lines := []string{"12", "", "7"}

	for i := 0; i < len(lines); i++ {
		if lines[i] == "" {
			continue
		}
		fmt.Println("three clauses:", lines[i])
	}

	i := 0
	for i < len(lines) {
		if lines[i] == "" {
			continue
		}
		fmt.Println("condition only:", lines[i])
		i++
	}
}
```

The second loop never ends, so it is built first and run under `timeout`, which kills it after
two seconds and exits with status 124 to say that it had to:

```
ana@vm:~/flow-skip$ go build
ana@vm:~/flow-skip$ timeout 2 ./skip; echo $?
three clauses: 12
three clauses: 7
condition only: 12
124
ana@vm:~/flow-skip$ go vet; echo $?
0
```

The first loop printed both numbers. The second printed `12`, reached the empty line with `i` at
1, and went back to its condition without ever reaching `i++`: `i` stayed 1, the line stayed
empty, and the program spun on the same turn for two seconds without printing anything. `go vet`
had nothing to say, because the compiler and `vet` cannot know the loop was meant to end.

So when a loop moves its own counter, move it before any `continue` can run, or write the loop
in the three-clause form, where the post statement runs after every turn, including one that
`continue` cut short.

## A loop you can see, in the same function

`break` and `continue` act on a loop that encloses them **in the same function**. A helper
function cannot end its caller's loop, however it is called:

```go
package main

import "fmt"

func check(n int) {
	if n < 0 {
		break
	}
	if n == 0 {
		continue
	}
	fmt.Println(n)
}

func main() {
	for _, n := range []int{3, 0, -1, 5} {
		check(n)
	}
}
```

```
ana@vm:~/flow-outside$ go build
# example.com/outside
./main.go:7:3: break is not in a loop, switch, or select
./main.go:10:3: continue is not in a loop
```

The two messages are not the same, and the difference is the subject of section 03. `continue`
belongs to loops alone. `break` is also allowed inside a `switch` and a `select`, and inside one
of those it leaves that statement rather than any loop around it. (`select` waits on channels,
which belong to the `go-concurrency` course.) The way to stop the caller's loop from a helper is
to return something the caller checks, such as a `bool`, and let the caller write the `break`.
