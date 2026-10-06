---
title: Length and capacity
version: 1
---

Lesson 11 drew a slice as three things over an array: where it starts, its length and its
capacity. The two numbers are easy to blur, and the usual way to blur them is to believe that the
length is as far as a slice can see. It is not. **The length is how far you may index; the
capacity is how far the slice may be stretched.** The array carries on past the length whether you
look at it or not.

Here is a week in an array, and a slice of the middle of it:

```go
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid, len(mid), cap(mid))

	more := mid[:5]
	fmt.Println(more, len(more), cap(more))

	fmt.Println(mid[3])
}
```

```
ana@vm:~/slices$ go run .
[wed thu] 2 5
[wed thu fri sat sun] 5 5
panic: runtime error: index out of range [3] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/slices/main.go:13 +0x19a
exit status 2
```

Three lines of output, and each one is a rule.

`week[2:4]` starts at `wed` and stops before index 4, so its length is 2. Its capacity is 5,
because that is how many elements the array has from `wed` to its end: `wed`, `thu`, `fri`, `sat`,
`sun`. The capacity is counted from where the slice **starts**, never from the start of the array.

`mid[:5]` reslices `mid` to a length of 5, longer than `mid` itself. That is allowed, and it shows
`fri`, `sat` and `sun`, which were in the array all along. **Reslicing upwards is legal as far as
the capacity**, and it hands you elements that the shorter slice never printed.

`mid[3]` is the same element as `more[3]`, `sat`, and still the program stopped. An index is checked
against the **length** and nothing else: `index out of range [3] with length 2` says which index
you asked for and which length refused it. The compiler let it through even though 3 is a constant,
because a slice's length is only known when the program runs. The lines under the message are a
stack trace, which lesson 37 reads frame by frame, and `exit status 2` is how a Go program that
panicked ends, which lesson 36 explains.

## Past the capacity

Stretching has a limit too. Asking `mid` for six elements, one more than its capacity:

```go
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid[:6])
}
```

```
ana@vm:~/slices-cap$ go run .
panic: runtime error: slice bounds out of range [:6] with capacity 5

goroutine 1 [running]:
main.main()
	/home/ana/slices-cap/main.go:8 +0x6a
exit status 2
```

This message names the **capacity**, where the last one named the length, and that difference is
the whole section in one line. Counting from `wed`, the array has five elements and no sixth, and
a slice never reaches back before its own start, so `mon` and `tue` are out of its reach whatever
you ask for.

| you write | it is checked against | past it |
|---|---|---|
| `s[i]` | `len(s)`: `i` must be less | `index out of range [i] with length n` |
| `s[:j]` | `cap(s)`: `j` may be equal | `slice bounds out of range [:j] with capacity n` |

The spare room between the length and the capacity is what `append` writes into, which is section
03's subject.
