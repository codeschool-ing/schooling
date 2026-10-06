---
title: Making, filling and emptying a map
version: 1
---

Lessons 11 to 13 kept values in a row and found each one by its position. A **map** finds a value
by a key instead: a name, a code, a checksum. Its type names both halves, so `map[string]int` is a map from strings to
ints. The runtime keeps it as a hash table, which means a lookup goes straight to the key instead
of walking past every entry before it.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tages := map[string]int{\n\t\t\"ana\": 31,\n\t\t\"bia\": 27,\n\t}\n\tfmt.Println(ages, len(ages))\n",
      "note": "**A map literal is the type followed by `key: value` pairs in braces.** The comma after the last pair is required when the closing brace sits on a line of its own, as it does here. `len` counts the keys."
    },
    {
      "code": "\n\tages[\"caio\"] = 45\n\tages[\"ana\"] = 32\n\tfmt.Println(ages, len(ages))\n",
      "note": "**Assigning to `m[key]` adds the key if it is new and replaces its value if it is not.** There is no separate insert: `caio` arrived and `ana` changed, so the length went from 2 to 3 and not to 4."
    },
    {
      "code": "\n\tdelete(ages, \"bia\")\n\tdelete(ages, \"zeca\")\n\tfmt.Println(ages, len(ages))\n",
      "note": "`delete` is a built-in function and removes a key with its value. Deleting a key that is not there, `zeca`, does nothing and is not an error."
    },
    {
      "code": "\n\tstock := make(map[string]int)\n\tstock[\"pear\"] = 3\n\tfmt.Println(stock, len(stock))\n}\n",
      "note": "**`make(map[K]V)` gives an empty map that is ready to write to**, the same as the literal `map[string]int{}`. `make` also takes a size, `make(map[string]int, 1000)`, which reserves room for that many keys and changes nothing else."
    }
  ],
  "output": "map[ana:31 bia:27] 2\nmap[ana:32 bia:27 caio:45] 3\nmap[ana:32 caio:45] 2\nmap[pear:3] 1"
}
```

`fmt.Println` writes a map as `map[key:value …]`, and in this output the keys happen to come out
in alphabetical order. That is `fmt` sorting them before it prints, not the order the map keeps,
and section 03 shows the difference.

A key appears once. A literal that names the same key twice is refused when it is compiled, since
one of the two values would be thrown away without anybody noticing:

```go
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31,
		"bia": 27,
		"ana": 32,
	}
	fmt.Println(ages)
}
```

```
ana@vm:~/maps-dup$ go run .
# example.com/dup
./main.go:9:3: duplicate key "ana" in map literal
```

## The nil map: read it, never write it

Lesson 6 printed the zero value of a map as `map[string]int(nil)`. **A map declared with `var` and
never made is nil, and a nil map behaves as an empty map in every way except one**: you cannot
store anything in it.

```go
package main

import "fmt"

func main() {
	var prices map[string]int
	fmt.Println(prices["pear"], len(prices), prices == nil)

	prices["pear"] = 3
	fmt.Println("this line is never reached")
}
```

```
ana@vm:~/maps-nil$ go run .
0 0 true
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/maps-nil/main.go:9 +0xc5
exit status 2
```

Reading `prices["pear"]` gave 0 and `len` gave 0, with no complaint. The assignment on line 9
stopped the program with a **panic**, Go's word for a failure at run time that the program did not
handle. Lesson 36 is about panics, and lesson 37 reads the trace printed below the message. The
compiler let this through because whether a map variable holds a map is only known when the
program runs.

This is the opposite of what lesson 12 showed for slices, where `append` to a nil slice simply
allocated an array. There is no `append` for maps. **A map you mean to write to has to come from
`make` or from a literal first**, and when a map is a field of something larger, forgetting to make
it is the usual way this panic arrives.

## What can be a key

A map has to compare a key it is given with the keys it holds, so **a key type must be comparable
with `==`**. Numbers, strings, booleans, pointers and arrays of those are. Slices, maps and
functions are not, and lesson 13 promised the compiler's answer:

```go
package main

import "fmt"

func main() {
	seen := map[[]byte]bool{}
	a := map[string]int{"x": 1}
	b := map[string]int{"x": 1}
	fmt.Println(seen, a == b)
}
```

```
ana@vm:~/maps-key$ go run .
# example.com/key
./main.go:6:14: invalid map key type []byte
./main.go:9:20: invalid operation: a == b (map can only be compared to nil)
```

The first error is the key type. The second is the same rule from the other side: **a map cannot
be compared with `==` either**, only checked against `nil`, which is why a map can never be the key
of another map. Lesson 13 used a `[32]byte` checksum as a key, which is the usual way round the
first error: an array of a fixed size is comparable where the slice of the same bytes is not.
Structs with comparable fields can be keys too, and lesson 15 is about structs.

Two things maps are not for in this course. A map read and written by two goroutines at once is the
`go-concurrency` course's subject, because a plain map is not safe for that. And `m["ana"]` is not
a variable you can take the address of, which lesson 23 explains.
