---
title: range, and what it hands you
version: 1
---

Python walks a list with `for lang in langs` and hands you each element. The Go line that looks the
same, `for lang := range langs`, does not: **with one variable, `range` over a slice gives you the
indices, not the elements.** The names you choose do not change that. Here are the three ways to
write it, side by side:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tlangs := []string{\"Go\", \"C\", \"Python\"}\n\n\tfor i, lang := range langs {\n\t\tfmt.Println(i, lang)\n\t}\n",
      "note": "**Two variables get the index and the element.** `range` produces them on every pass, in order, from index 0 to the last."
    },
    {
      "code": "\n\tfor lang := range langs {\n\t\tfmt.Print(\" \", lang)\n\t}\n\tfmt.Println()\n",
      "note": "One variable gets the index alone. It is called `lang` here, and it still holds 0, 1 and 2, which is the line of output a Python habit does not expect."
    },
    {
      "code": "\n\tfor _, lang := range langs {\n\t\tfmt.Print(\" \", lang)\n\t}\n\tfmt.Println()\n}\n",
      "note": "To get the elements alone, discard the index with `_`, the blank identifier. Declaring `i` and never using it would be the compile error of lesson 5."
    }
  ],
  "output": "0 Go\n1 C\n2 Python\n 0 1 2\n Go C Python"
}
```

## The value is a copy

On every pass, `range` assigns the element to the value variable, and an assignment in Go copies.
So the variable holds a copy of the element, and changing it changes the copy. With a slice of
lesson 15's structs, the difference is easy to miss:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	team := []Player{{"Ana", 10}, {"Bia", 7}}

	for _, p := range team {
		p.Score += 5
	}
	fmt.Println(team)

	for i := range team {
		team[i].Score += 5
	}
	fmt.Println(team)
}
```

```
ana@vm:~/loops-copy$ go run .
[{Ana 10} {Bia 7}]
[{Ana 15} {Bia 12}]
ana@vm:~/loops-copy$ go vet; echo $?
0
```

The first loop added 5 to each player's score, and the team printed afterwards has the old scores.
`p` was a copy of `team[0]` and then of `team[1]`, each thrown away at the end of its pass. The
second loop wrote through the index, `team[i].Score`, which is the element in the slice itself,
and that one stuck. `go vet` exited 0: a loop that changes its own copy is legal and sometimes
intended, so nothing warns you. **To change the elements of a slice in a loop, write to
`s[i]`, never to the value variable.**

## The slice is read once

`range` looks at its slice once, before the first pass, and decides then how many passes there will
be. A loop that appends to the slice it is walking does not chase its own tail:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	for _, n := range nums {
		nums = append(nums, n*10)
	}
	fmt.Println(nums)
}
```

```
ana@vm:~/loops-once$ go run .
[1 2 3 10 20 30]
```

Three passes, because `nums` had three elements when the loop started, and three new ones at the
end. A three-clause loop is different on exactly this point: its condition is tested again before
every pass, as the figure in section 02 showed. Written as `for i := 0; i < len(nums); i++` with the
same `append` inside, `len(nums)` would grow by one on every pass, as fast as `i` does, and the
loop would never end. That version was not run in the lab, for that reason.

## A new pair of variables on every pass

Since Go 1.22, **each pass of a loop gets its own `i` and its own `lang`**, new variables that happen
to have the same names, rather than one pair overwritten again and again. Inside the body you
cannot tell the difference, and nothing in this lesson depends on it. It matters when something
keeps hold of a loop variable after its pass is over. Lesson 2 ran a program whose output changed
when only the `go` line of its `go.mod` moved from 1.21 to 1.22, and lesson 21, on closures,
explains what was holding on to the variable.
