---
title: Where an array is the right type
version: 1
---

After lesson 12 it is tempting to conclude that arrays are the slice's plumbing, something the
language needs underneath and a program never wants for itself. Sections 02 and 03 met two
functions that disagree, `sha256.Sum256` and `netip.AddrFrom4`. **An array is the right type when
the size is part of what the value means, and in return it can do two things a slice cannot: be
compared with `==` and be a map key.**

## `==` works on arrays

Lesson 11 compared two arrays with `==`. Checksums are where that pays off, because comparing two
32-byte checksums stands in for comparing two whole contents:

```go
package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
)

func main() {
	x := []byte("hello")
	y := []byte("hello")
	fmt.Println(sha256.Sum256(x) == sha256.Sum256(y))
	fmt.Println(bytes.Equal(x, y))
}
```

```
ana@vm:~/slicearray-eq$ go run .
true
true
```

The first line compares two `[32]byte` values, element by element, with the operator. The second
compares the slices themselves and needs a function to do it, because between two slices the
operator is refused, as lesson 11 showed: `slice can only be compared to nil`. Lesson 11 also gave
the reason. Two slices could be equal in two senses that disagree, the same elements or the same
window onto the same array, so Go makes you name the one you mean, here with `bytes.Equal`. **An
array has no such ambiguity: it is its elements, so `==` has one meaning**, and that single meaning
is what lets an array be a map key.

## An array as a map key

A map needs keys it can compare, so the same rule decides which types may be keys. Maps are lesson
14's subject; what this program needs from them is that `seen[sum]` gives back the name stored
under `sum`, or the empty string if there is none:

```go
package main

import (
	"crypto/sha256"
	"fmt"
)

func main() {
	names := []string{"a.txt", "b.txt", "c.txt", "d.txt"}
	bodies := []string{"hello", "world", "hello", "hello\n"}

	seen := map[[32]byte]string{}
	for i := 0; i < len(names); i++ {
		sum := sha256.Sum256([]byte(bodies[i]))
		if seen[sum] != "" {
			fmt.Println(names[i], "has the same contents as", seen[sum])
			continue
		}
		seen[sum] = names[i]
	}
	fmt.Println(len(seen), "different contents")
}
```

```
ana@vm:~/slicearray-dedup$ go run .
c.txt has the same contents as a.txt
3 different contents
```

Four files and three different contents: `c.txt` repeats `a.txt` byte for byte, and `d.txt` is the
same word with a newline after it, which is a different checksum. The key is the whole 32-byte
array, compared exactly. With `[]byte` as the key type the program would not compile, and lesson 14
shows that refusal; converting each checksum to a `string` would work, and would be a second
representation of something that already had a perfectly good type.

The price of all this is the one lesson 11 described: an array is a value, so assigning it or
passing it copies every element. For 32 bytes that is nothing worth thinking about. For an array of
a million elements it is a real cost, and lesson 22 measures it. **Keep arrays for values with a
small, fixed size that means something, and slices for everything that is a list.**
