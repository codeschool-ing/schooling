---
title: What an import may and may not do
version: 1
---

An import line looks like a request that always succeeds if the path exists. Two rules can refuse it
even then, and both are about the shape of the graph section 02 drew. Then there are four ways to
write the line itself, and the last of them is worth knowing mostly to recognise.

## No cycles

Suppose `fold` wanted to ask whether a word is one of a list of common words, and the list it
reached for was a `text.Counts`. In a copy of the module, `fold.go` imports `text`:

```go
// Package fold puts a word into the form package text compares.
package fold

import (
	"strings"
	"unicode"

	"example.com/wordy/text"
)

// Common reports whether w is one of the words in common.
func Common(w string, common text.Counts) bool {
	return common[Word(w)] > 0
}

// Word lower-cases w and trims anything but letters and digits from its ends.
func Word(w string) string {
	return strings.TrimFunc(strings.ToLower(w), func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
}
```

```
ana@vm:~/pkgs-cycle$ go build ./...; echo $?
package example.com/wordy/cmd/wordcount
	imports example.com/wordy/text from main.go
	imports example.com/wordy/internal/fold from count.go
	imports example.com/wordy/text from fold.go: import cycle not allowed
1
```

The message walks the chain from a program down to the arrow that points back up, naming the file
that wrote each import. **Go refuses an import cycle outright**, between two packages or through
twenty. A package is compiled after everything it imports, and in a cycle there is no first one to
compile; the same order decides which package's initialisation runs first, further down this page.

The way out is never a trick with the import line. It is to move something. Here `Common` needs only
a `map[string]int`, so it can take one and drop the import; or the function belongs in `text`, next
to the type it reads. A cycle is the compiler telling you that two packages are really one, or that
a piece of one belongs in the other.

## internal: a directory nobody else may import

`fold` sits under a directory called `internal`, and the go command treats that name specially. The
rule is a comment in `cmd/go/internal/load/pkg.go`: "An import of a path containing the element
“internal” is disallowed if the importing code is outside the tree rooted at the parent of the
“internal” directory." The parent of `internal` here is the root of `example.com/wordy`, so every
package of the module may import `fold`, and no other module may.

Checking that needs a second module that can see this one. Lesson 3's workspace does exactly that:
in `~/pkgs-work`, a copy of the module sits in `wordy`, and beside it a module `example.com/other`
whose program imports one package from each side of the line:

```go
package main

import (
	"fmt"

	"example.com/wordy/internal/fold"
	"example.com/wordy/text"
)

func main() {
	fmt.Println(len(text.Count("one two two")), fold.Word("Hello!"))
}
```

```
ana@vm:~/pkgs-work$ go work init ./wordy ./other
ana@vm:~/pkgs-work$ go run ./other; echo $?
package example.com/other
	other/main.go:6:2: use of internal package example.com/wordy/internal/fold not allowed
1
```

`text` passed and `fold` did not. **`internal` is how a module keeps a package to itself.** It works
at a different scale from a lower-case name: a lower-case name is hidden from every other package,
while a package under `internal/` keeps its exported names usable across your own packages and hides
them from everybody else's. Those names are an API for your module only, free to change in any
release, because nobody outside can have used them.

## Four ways to write an import

The ordinary import binds the package's name. When two packages share a name, the second has to be
given another one, an **alias**. `crypto/rand` and `math/rand/v2` are both `package rand`:

```go
package main

import (
	"crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(10), len(rand.Text()))
}
```

```
ana@vm:~/pkgs-rand$ go build
# example.com/dice
./main.go:6:2: rand redeclared in this block
	./main.go:4:2: other declaration of rand
./main.go:6:2: "math/rand/v2" imported as rand and not used
./main.go:10:19: undefined: rand.N
```

An alias written before the path fixes it, and the file then uses the alias:

```go
package main

import (
	crand "crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(1), len(crand.Text()))
}
```

```
ana@vm:~/pkgs-alias$ go run .
0 26
```

`rand.N(1)` asks for a number below 1, so this run prints the same thing every time; `crand.Text()`
returns a random string meant for secrets and tokens, and its length is all the program shows. Keep
aliases for collisions like this one. An alias chosen for brevity makes every reader learn a second
name for a package they already know.

### The blank import, and init

An import whose name is `_` binds no name at all. It exists for a package's side effects: importing
a package runs its `init` functions, and some packages do their work there. `image.DecodeConfig`
reads the size of an image in any format that has been registered with the `image` package, and
nothing is registered by default:

```go
package main

import (
	"fmt"
	"image"
	"os"
)

func main() {
	f, err := os.Open("/usr/local/go/src/image/png/testdata/gray-gradient.png")
	if err != nil {
		fmt.Println(err)
		return
	}
	cfg, format, err := image.DecodeConfig(f)
	f.Close()
	fmt.Printf("%q %dx%d %v\n", format, cfg.Width, cfg.Height, err)
}
```

```
ana@vm:~/pkgs-png$ go run .
"" 0x0 image: unknown format
ana@vm:~/pkgs-png$ sed -i "s|\"image\"$|&\n\t_ \"image/png\"|" main.go && sed -n 3,8p main.go
import (
	"fmt"
	"image"
	_ "image/png"
	"os"
)
ana@vm:~/pkgs-png$ go run .
"png" 1x16 <nil>
ana@vm:~/pkgs-png$ grep -n "func init" -A2 /usr/local/go/src/image/png/reader.go
1052:func init() {
1053-	image.RegisterFormat("png", pngHeader, Decode, DecodeConfig)
1054-}
```

The program never names `png`, and without the `_` the compiler would refuse the unused import, as
lesson 4 showed. The last command shows what the import was for: `image/png` registers its decoder
in an `init` function. **`init` takes no arguments, returns nothing, cannot be called, and runs by
itself** once the package's variables are set. The order is fixed, and a small module shows it:

```go
// Package reg keeps a list that other packages add to.
package reg

import "fmt"

var Names []string

func init() {
	fmt.Println("reg: init")
}
```

```go
package main

import (
	"fmt"

	"example.com/order/reg"
)

var greeting = say("main: package variable")

func say(s string) string {
	fmt.Println(s)
	return s
}

func init() {
	reg.Names = append(reg.Names, "main")
	fmt.Println("main: init")
}

func main() {
	fmt.Println("main: main", reg.Names)
}
```

```
ana@vm:~/pkgs-init$ go run .
reg: init
main: package variable
main: init
main: main [main]
```

An imported package is initialised completely before the package that imports it: `reg` first. Then
`main`'s own package variables, then its `init`, and only then `main`. That is why `main` could
append to `reg.Names` in `init` and find the list ready. It is also why the cycle at the top of this
section has no answer: with `text` and `fold` importing each other, neither can go first. Use `init`
sparingly. Work done there runs for every program that imports the package, whether it needed the
work or not, and `init` has no way to return an error.

### The dot import

The last form, `.`, puts the package's exported names into the file as if they were declared there:

```go
package main

import (
	"fmt"
	. "strings"
)

func Title(s string) string {
	return ToUpper(s[:1]) + s[1:]
}

func main() {
	fmt.Println(Title("go"), Repeat("!", 3))
}
```

```
ana@vm:~/pkgs-dot$ go run .
# example.com/dot
./main.go:8:6: Title already declared through dot-import of package strings ("strings")
	$GOROOT/src/strings/strings.go:849:6: other declaration of Title
```

`ToUpper` and `Repeat` worked without `strings.` in front, and the cost arrived at once: `strings`
already has a `Title`, at line 849 of its source, and now every exported name of `strings` is a name
this file may not declare. Worse is the cost to a reader, who sees `Repeat("!", 3)` and cannot tell
whether it is declared in this package or which import supplied it. **Write the package name.** It
is what makes `text.Count` and `fold.Word` say where they come from, and it is why Go names are
short: `strings.Repeat` does not need to be called `RepeatString`.
