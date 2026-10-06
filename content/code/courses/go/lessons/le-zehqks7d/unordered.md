---
title: No order, on purpose
version: 1
---

A Python dictionary gives its keys back in the order they were inserted, and so does a JavaScript
object for most keys, so a programmer arriving from either expects a map to have *some* order.
**A Go map has none.** Walking it with `range`, the loop of lesson 17, visits every key once, and
the order of the visit is chosen afresh every time:

```go
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	var walked []string
	for name, age := range ages {
		walked = append(walked, fmt.Sprint(name, ":", age))
	}
	fmt.Println(walked)
	fmt.Println(ages)
}
```

```
ana@vm:~/maps-order$ go run .
[caio:45 davi:19 gil:23 ana:31 bia:27 eva:38 fabio:52 hana:29 igor:61 joana:34]
map[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
ana@vm:~/maps-order$ go run .
[bia:27 caio:45 davi:19 fabio:52 hana:29 igor:61 joana:34 ana:31 eva:38 gil:23]
map[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
```

The same program, the same map, run twice: the walk started at `caio` once and at `bia` the next
time. The second line of each run is identical, and that is the trap. **`fmt.Println` sorts a
map's keys before printing it**, so the one tool a beginner uses to look at a map is the one that
shows an order the map does not have. The sorting is in `fmt`'s source, which calls the internal
package `fmtsort` to order the keys; the map itself is never sorted.

## Random by design

The variation is not a side effect of how the map happens to be stored. It is put there. In the
runtime's source for go1.27.1, `internal/runtime/maps/table.go`, every walk over a map begins with
`it.entryOffset = rand()`, which starts the visit at a random place. The documentation says the same thing in words, here
for `maps.Keys`, which hands out a map's keys one at a time:

```
ana@vm:~/maps-small$ go doc maps.Keys
package maps // import "maps"

func Keys[Map ~map[K]V, K comparable, V any](m Map) iter.Seq[K]
    Keys returns an iterator over keys in m. The iteration order is not
    specified and is not guaranteed to be the same from one call to the next.
```

The square brackets in the signature are generics, lessons 30 and 31; the sentence under it is what
matters here. The randomness exists so that a program cannot come to depend on an order, and it
works best on big maps. On a small one it is weaker than it looks. A map that has never held more than
eight keys keeps them all in a single group of eight slots. The random start only chooses
which slot to begin at, so four keys come out in the order they went in, rotated:

```go
package main

import "fmt"

func main() {
	steps := map[string]int{"build": 1, "test": 2, "push": 3, "deploy": 4}
	var walked []string
	for step := range steps {
		walked = append(walked, step)
	}
	fmt.Println(walked)
}
```

```
ana@vm:~/maps-small$ go build && for i in 1 2 3 4 5 6; do ./small; done
[build test push deploy]
[test push deploy build]
[build test push deploy]
[deploy build test push]
[build test push deploy]
[build test push deploy]
```

Four runs out of six gave the order the literal was written in. **A test that walks a small map
and expects that order passes most of the time and fails some of the time.** That is the most expensive kind of test there
is, because the first few failures get blamed on the machine. The
group of eight is how go1.27.1 builds maps, not a promise of the language, and the only order the
language promises is none.

## An order you choose

When the order matters, for output somebody reads or for a file that must come out the same twice,
take the keys out, sort them, and walk the sorted slice:

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	names := slices.Sorted(maps.Keys(ages))
	var walked []string
	for i := 0; i < len(names); i++ {
		walked = append(walked, fmt.Sprint(names[i], ":", ages[names[i]]))
	}
	fmt.Println(walked)
}
```

```
ana@vm:~/maps-sorted$ go run .
[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
```

`maps.Keys(ages)` produces the keys in the map's own random order, and `slices.Sorted` collects
them into a new `[]string` and sorts it. From there it is an ordinary slice, walked by index as in
lessons 11 to 13, and every lookup `ages[names[i]]` finds its key. **The map answers "what is the
value for this key"; the sorted slice answers "in what order".** Keeping the two jobs apart is the
whole technique, and it costs one slice of keys.
