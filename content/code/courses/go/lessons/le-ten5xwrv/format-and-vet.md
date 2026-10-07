---
title: gofmt, go vet and the compiler's opinions
version: 1
---

Three programs read your code before it runs, and each one catches a different kind of thing. The
compiler refuses what is not Go. `gofmt` rewrites what is Go but laid out differently from
everybody else's. `go vet` reports what is valid Go and almost certainly a mistake.

## gofmt: one layout, chosen once

Here is a program that compiles and runs, typed by somebody in a hurry:

```go
package main
import "fmt"
func main(){
    name:="Ana"
  fmt.Println( "Hello,",name )
}
```

`gofmt -l` lists the files whose layout differs from the standard one, and `-d` shows the
difference as a diff:

```
ana@vm:~/tidy$ gofmt -l .
main.go
ana@vm:~/tidy$ gofmt -d main.go
diff main.go.orig main.go
--- main.go.orig
+++ main.go
@@ -1,6 +1,8 @@
 package main
+
 import "fmt"
-func main(){
-    name:="Ana"
-  fmt.Println( "Hello,",name )
+
+func main() {
+	name := "Ana"
+	fmt.Println("Hello,", name)
 }
```

`go fmt` applies it to the files of the package and names the ones it changed:

```
ana@vm:~/tidy$ go fmt
main.go
ana@vm:~/tidy$ cat main.go
package main

import "fmt"

func main() {
	name := "Ana"
	fmt.Println("Hello,", name)
}
```

**There are no options for the layout itself.** No indent width, no brace style, no line length.
That is the design: in a language where one program formats every file, a diff between two
versions shows what somebody changed and never how their editor was configured, and a code review
never spends a comment on where a brace goes. Most editors run `gofmt` on save, and a Go file that
is not formatted looks as wrong to a Go programmer as a misspelt word.

## The compiler refuses more than you expect

Some languages warn about an unused import. Go refuses to build:

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("Hello, Go")
}
```

```
ana@vm:~/unused$ go run .; echo $?
# example.com/unused
./main.go:5:2: "os" imported and not used
1
```

`./main.go:5:2` is file, line and column: line 5, the second character, where `"os"` starts after
the tab. A local variable declared and never used is refused the same way, which lesson 5 shows.
Both rules exist for the same reason: an import costs compile time and a binary's size, and an
unused variable is often a typo for one that is used. A warning gets ignored; an error gets fixed.

## go vet: valid, and wrong

This one compiles, runs and prints something nobody wanted:

```go
package main

import "fmt"

func main() {
	name := "Ana"
	fmt.Printf("Hello, %d\n", name)
}
```

```
ana@vm:~/vet$ go run .
Hello, %!d(string=Ana)
ana@vm:~/vet$ go vet; echo $?
main.go:7:21: fmt.Printf format %d has arg name of wrong type string
1
```

`%d` asks `Printf` for a whole number and it was handed a string, so it printed its complaint into
the output instead of crashing: `%!d(string=Ana)` is `fmt` saying which verb went wrong and what it
received. The compiler cannot catch this, because the format is just a string to it. **`go vet`
reads the format string and checks the arguments against it**, along with a few dozen other
patterns that are legal Go and nearly always bugs.

`go test` runs a selection of the same checks automatically before it runs any test, which is why
this mistake rarely reaches anybody in a project with tests. In one without them, `go vet` is the
command to run before anybody else reads the code.

So the order, before you show anyone a Go file, is short:

1. `go fmt` to lay it out.
2. `go vet` to find the mistakes that compile.
3. `go build`, which the other two do not replace.
