---
title: Complex numbers, built in
version: 1
---

Go has complex numbers in the language itself, as Python does, rather than in a library. Most
programs never use them. Signal processing, electrical engineering and some geometry do, and for
those they save a page of code. There are two types: `complex128`, made of two
`float64`s, and `complex64`, made of two `float32`s.

```go
package main

import (
	"fmt"
	"math"
	"math/cmplx"
)

func main() {
	z := complex(3, 4)
	fmt.Println(z, real(z), imag(z))
	fmt.Println(cmplx.Abs(z))

	w := 2i
	fmt.Println(w * w)

	fmt.Println(math.Sqrt(-1), cmplx.Sqrt(-1))
	fmt.Printf("%T\n", z)
}
```

```
ana@vm:~/numbers-complex$ go run .
(3+4i) 3 4
5
(-4+0i)
NaN (0+1i)
complex128
```

`complex(3, 4)` builds the number 3 + 4i, and the built-in functions `real` and `imag` take it
apart again. A number literal ending in `i` is imaginary, so `2i` is a complex number on its own,
and `2i * 2i` is −4, as it should be. **Arithmetic works on complex numbers with the ordinary
operators**; anything beyond arithmetic, such as the absolute value, which is 5 for 3 + 4i, lives in
the package `math/cmplx`.

The square root shows why the two packages are separate. `math.Sqrt(-1)` works among the real
numbers, where −1 has no square root, so it returns `NaN`, as section 03 showed. `cmplx.Sqrt(-1)`
works among the complex numbers, where the answer is `i`, printed as `(0+1i)`. **Which package you
call decides which numbers the answer is allowed to be.**
