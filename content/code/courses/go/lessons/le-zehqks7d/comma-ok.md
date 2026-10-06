---
title: A missing key and the comma-ok idiom
version: 1
---

In Python, asking a dictionary for a key it does not have raises an error. **In Go, asking a map
for a missing key is not an error at all: you get the zero value of the value type**, and nothing
tells you it was missing. That is convenient most of the time and wrong exactly when the zero is a
value somebody could have stored.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tstock := map[string]int{\"apple\": 0, \"pear\": 3}\n\tfmt.Println(stock[\"pear\"], stock[\"apple\"], stock[\"kiwi\"])\n",
      "note": "Apples are on the list with nothing in stock, and kiwis are not on the list. **Both lookups print `0`**, so from this line alone the two cannot be told apart."
    },
    {
      "code": "\n\tn, ok := stock[\"apple\"]\n\tfmt.Println(n, ok)\n\tn, ok = stock[\"kiwi\"]\n\tfmt.Println(n, ok)\n",
      "note": "**Asked for two results, a lookup also returns a `bool` that is `true` only if the key is present.** By convention it is called `ok`, and that name gives the idiom its name: comma-ok."
    },
    {
      "code": "\n\tif _, ok := stock[\"kiwi\"]; !ok {\n\t\tfmt.Println(\"kiwi is not on the list at all\")\n\t}\n}\n",
      "note": "The form you will meet most often: the lookup inside the `if`, with `_` discarding the value when only presence matters. The statement before the semicolon belongs to the `if`, which lesson 19 explains."
    }
  ],
  "output": "3 0 0\n0 true\n0 false\nkiwi is not on the list at all"
}
```

So there are two ways to read a map, and choosing between them is a question about your data.
**When the zero value cannot be a real entry, the single-value lookup is enough. When it can,
ask for `ok`.** A map from names to ages, where nobody is aged 0, can use `ages[name] == 0` to mean
"unknown". A stock list, where 0 is a perfectly good quantity, cannot, and a program that tested
`stock["apple"] == 0` would report apples as an item it has never heard of.

The same two-result form, with the same name for the second value, appears in two other places of
the language: asking an interface value what it holds, in lesson 29, and receiving from a channel,
in the `go-concurrency` course.

## The zero value doing the work

The silence about missing keys is also what makes the commonest map code short. Counting words is
one line inside the loop:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	words := strings.Fields("the cat saw the dog and the dog saw the cat run")
	counts := map[string]int{}
	for i := 0; i < len(words); i++ {
		counts[words[i]]++
	}
	fmt.Println(counts)

	names := []string{"ana", "bruno", "alice", "caio", "bia"}
	byInitial := map[string][]string{}
	for i := 0; i < len(names); i++ {
		first := names[i][:1]
		byInitial[first] = append(byInitial[first], names[i])
	}
	fmt.Println(byInitial)
}
```

```
ana@vm:~/maps-count$ go run .
map[and:1 cat:2 dog:2 run:1 saw:2 the:4]
map[a:[ana alice] b:[bruno bia] c:[caio]]
```

`counts[words[i]]++` reads the count, adds one and stores it back. The first time a word appears
there is nothing to read, so the read gives 0 and the word is stored with 1. **No check for "is
this word new?" is needed, because the zero value of `int` is the right starting count.**

The second loop groups names by their first letter, and it works for the same reason one level
down. `byInitial["a"]` starts as the zero value of `[]string`, which is a nil slice, and lesson 12
showed that `append` to a nil slice allocates the array itself. Each name is appended to its
group, and the first name of a group creates the group. `names[i][:1]` is the first byte of the
name, which is the first letter only because these names are plain ASCII; lesson 9 showed why
slicing a string is slicing bytes.

Both loops depend on the map having been made. `counts := map[string]int{}` is a map;
`var counts map[string]int` would be the nil map of section 02, and the first `++` would panic.
