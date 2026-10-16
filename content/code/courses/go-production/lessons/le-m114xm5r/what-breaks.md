`who/main.go`:

```go
// Command who prints the user running it and their home directory.
package main

import (
	"fmt"
	"os/user"
)

func main() {
	u, err := user.Current()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(u.Username, u.HomeDir)
}
```

`twice/main.go`:

```go
// Command twice asks a C function to double a number.
package main

// int twice(int x) { return 2 * x; }
import "C"

import "fmt"

func main() {
	fmt.Println(C.twice(21))
}
```
