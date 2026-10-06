---
title: From an array to a slice
version: 1
---

Lesson 11 sliced arrays to make views of part of them. Slicing with no numbers at all, `a[:]`, gives
a view of the whole array, and it is the direction of conversion you will use most. It is easy to
read `a[:]` as "the array, turned into a slice", as if something were turned. Nothing is. **`a[:]`
is a slice whose pointer is the array's first element, with the array's length as both its length
and its capacity; the elements stay where they were.**

```go
package main

import "fmt"

func main() {
	a := [4]int{1, 2, 3, 4}
	s := a[:]
	s[0] = 100
	fmt.Println(a, s, len(s), cap(s))
}
```

```
ana@vm:~/slicearray$ go run .
[100 2 3 4] [100 2 3 4] 4 4
```

Writing through `s` changed `a`, because there is only one set of four `int`s. Length 4 and
capacity 4: the slice reaches exactly as far as the array does, and the first `append` to it will
have to copy, as lesson 12 showed for any slice with no room left.

## Why you need it: functions take slices

Most of the standard library takes slices, because a slice works for any length and an array type
fixes one. Some functions return arrays, for the reasons section 04 is about. `sha256.Sum256` is
the one you will meet first:

```
ana@vm:~/slicearray-hash$ go doc crypto/sha256.Sum256
package sha256 // import "crypto/sha256"

func Sum256(data []byte) [Size]byte
    Sum256 returns the SHA256 checksum of the data.

```

`Size` is a constant, 32, so the result is a `[32]byte`. Handing that array to
`hex.EncodeToString`, which takes a `[]byte`, is the obvious thing to try, and so is skipping the
variable:

```go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum))
	fmt.Println(hex.EncodeToString(sha256.Sum256([]byte("hello"))[:]))
}
```

```
ana@vm:~/slicearray-hash$ go run .
# example.com/hash
./main.go:11:33: cannot use sum (variable of type [32]byte) as []byte value in argument to hex.EncodeToString
./main.go:12:33: cannot slice unaddressable value sha256.Sum256([]byte("hello")) (value of type [32]byte)
```

Two refusals, and they are different.

The first is the rule from lesson 10 applied to arrays: **Go never converts on your behalf, and a
`[32]byte` is not a `[]byte`**, however alike they look. One is 32 bytes; the other is a pointer, a
length and a capacity. You have to write the slice expression yourself.

The second is about where the slice would point. A slice is a pointer into an array, so the array
has to be somewhere a pointer can reach: in a variable, a field, an element of another array. The
array a function returns is a value nobody has stored yet, and the compiler calls such a value
**unaddressable**. Slicing it is refused rather than quietly storing it for you. The fix is the
variable the first line already had:

```go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum[:]))
}
```

```
ana@vm:~/slicearray-hash$ go run .
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

Sixty-four hexadecimal digits, two for each of the 32 bytes. `sum[:]` lends `EncodeToString` a
view of the array in `sum`, and nothing was copied to make it.
