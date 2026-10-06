---
title: How `append` grows a slice
version: 1
---

A slice is often described as a dynamic array that resizes itself, and the description hides the
one thing worth knowing. **Nothing in a slice ever resizes. When the array is full, `append`
allocates a new and bigger one, copies every element across, and returns a slice over the copy.**
The old array is left where it was. The built-in's own documentation says so, and says nothing
about how much bigger:

```
ana@vm:~/slices-grow$ go doc builtin.append
package builtin // import "builtin"

func append(slice []Type, elems ...Type) []Type
    The append built-in function appends elements to the end of a slice.
    If it has sufficient capacity, the destination is resliced to accommodate
    the new elements. If it does not, a new underlying array will be allocated.
    Append returns the updated slice. It is therefore necessary to store the
    result of append, often in the variable holding the slice itself:

        slice = append(slice, elem1, elem2)
        slice = append(slice, anotherSlice...)

    As a special case, it is legal to append a string to a byte slice, like
    this:

        slice = append([]byte("hello "), "world"...)

```

"It is therefore necessary to store the result" is the rule lesson 11 arrived at from the other
side. A new array means a new pointer in the slice, and only the slice `append` returns has it.

## Watching it happen

This program appends 2,000 numbers one at a time and prints a line whenever the capacity changes.
The `for` loop is lesson 17's subject; read it as "for each `i` from 0 to 1999".

```go
package main

import "fmt"

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
}
```

```
ana@vm:~/slices-grow$ go run .
len    1  cap    4
len    5  cap    8
len    9  cap   16
len   17  cap   32
len   33  cap   64
len   65  cap  128
len  129  cap  256
len  257  cap  512
len  513  cap  848
len  849  cap 1280
len 1281  cap 1792
len 1793  cap 2560
```

Two thousand appends and twelve lines: the capacity changed twelve times, so `append` made twelve
arrays and copied into each of them. Every other append wrote into room that was already there,
which is why appending one element at a time is not the disaster it looks like. The table reads in
three parts.

**From 8 to 512, each new array is twice the old one.** That is the rule in the runtime's source,
which ships with the toolchain, in a function called `nextslicecap`:

```
ana@vm:~/slices-grow$ grep -n "^func nextslicecap" -A 15 /usr/local/go/src/runtime/slice.go
326:func nextslicecap(newLen, oldCap int) int {
327-	newcap := oldCap
328-	doublecap := newcap + newcap
329-	if newLen > doublecap {
330-		return newLen
331-	}
332-
333-	const threshold = 256
334-	if oldCap < threshold {
335-		return doublecap
336-	}
337-	for {
338-		// Transition from growing 2x for small slices
339-		// to growing 1.25x for large slices. This formula
340-		// gives a smooth-ish transition between the two.
341-		newcap += (newcap + 3*threshold) >> 2
```

Below a capacity of 256 the answer is `doublecap`. From 256 on, line 341 adds a quarter of the
capacity plus 192 (`3*threshold` is 768, and `>> 2` divides by four), so the factor falls from 2
towards 1.25 as the slice grows. At exactly 256 that still comes to 512, which is why the 257th
append doubled too. Lines 329 and 330 cover appending many elements at once: if even double is
too small, the new capacity is just the length asked for.

**After 512 the numbers stop being round, and the formula is not the reason.** It says
`512 + (512 + 768) / 4`, which is 832. But 832 `int`s are 6,656 bytes, and Go's memory allocator
does not hand out any size you ask for; it rounds up to one of a fixed list of **size classes**.
The list is in the source too:

```
ana@vm:~/slices-grow$ sed -n "6p;53,55p" /usr/local/go/src/internal/runtime/gc/sizeclasses.go
// class  bytes/obj  bytes/span  objects  tail waste  max waste  min align
//    47       6144       24576        4           0     12.48%       2048
//    48       6528       32768        5         128      6.23%        128
//    49       6784       40960        6         256      4.36%        128
```

6,528 bytes is too small for 6,656, so the array is 6,784 bytes, and `append` uses all of it:
6,784 divided by 8 bytes an `int` is 848. The same rounding turns the formula's 1,252 into 1,280
on the next line.

## The first line is the compiler's

The rule would start at 1 for the first element, and the table starts at 4. That first array was
chosen before the runtime was asked: the compiler gives a slice that never leaves its function a
32-byte buffer for its first elements, and 32 bytes hold four `int`s. Add one line at the end that
keeps `s` in a package-level variable, and the same loop starts differently:

```
ana@vm:~/slices-grow-kept$ go run . | head -6
len    1  cap    1
len    2  cap    2
len    3  cap    3
len    4  cap    4
len    5  cap    8
len    9  cap   16
```

Where a value lives, and how the compiler decides, is lesson 24. The point here is narrower: **the
capacities are chosen by the compiler and the runtime of the Go you are running, and no program
should depend on them.** The documentation promises a big enough array and nothing else. Code
that needs a capacity says so, with `make`, which is section 04.
