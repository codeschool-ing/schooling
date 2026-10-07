---
title: What a capital letter means
version: 1
---

Lesson 4 said that the capital P in `fmt.Println` is what lets another package call it, and every
lesson since has written capitals without saying why. A reader from Java or C# looks for the keyword
that makes a name public, and Go has none; a reader from Python takes the case for a style. **In Go
the first letter of a name is the access rule.** A name that starts with an upper-case letter is
**exported**, visible to every package that imports this one. Any other name is visible inside its
own package and nowhere else. `go doc go/token.IsExported` says it in one line: "IsExported reports
whether name starts with an upper-case letter."

The rule covers every name declared at the top of a package, functions, types, variables and
constants, and two kinds of name that do not belong to the package's scope: a struct's fields and a
type's methods. `text` from section 02 uses all of them. `Count`, `Counts`, `Entry` and `Top` are
exported; `entries` and `byCount` are not. A program in the same module that reaches for the
lower-case ones, `cmd/peek` in a copy of the module, gets three refusals:

```go
package main

import (
	"fmt"

	"example.com/wordy/text"
)

func main() {
	c := text.Count("one two two")
	fmt.Println(c.entries())
	fmt.Println(text.byCount(text.Entry{"a", 1}, text.Entry{"b", 2}))
	var e text.Entry
	fmt.Println(e.word)
}
```

```
ana@vm:~/pkgs-peek$ go build ./cmd/peek
# example.com/wordy/cmd/peek
cmd/peek/main.go:11:16: c.entries undefined (cannot refer to unexported method entries)
cmd/peek/main.go:12:19: undefined: text.byCount
cmd/peek/main.go:14:16: e.word undefined (type text.Entry has no field or method word, but does have field Word)
```

The three messages are worth reading apart. The method exists and the compiler says so: it is
**unexported**, the word for a lower-case name seen from outside. The function gets a bare
`undefined`, as if `text` had never declared it, and from outside the package that is the truth. The
field `word` never existed, and the compiler noticed the exported `Word` one letter away. Being in
the same module changed nothing; **the boundary is the package**, and `cmd/peek` is another package.

Inside `text`, on the other hand, nothing is hidden from anything. `top.go` called `c.entries()` and
passed `byCount` to `slices.SortFunc` without a second thought, and `count.go` could do the same.

## Exported names are a promise

`go doc` shows a package the way an importer sees it, which means exported names only. `-u` adds the
unexported ones:

```
ana@vm:~/pkgs$ go doc ./text Counts
package text // import "example.com/wordy/text"

type Counts map[string]int
    Counts maps each word to the number of times it appears.

func Count(s string) Counts
func (c Counts) Top(n int) []Entry
ana@vm:~/pkgs$ go doc -u ./text Counts
package text // import "example.com/wordy/text"

type Counts map[string]int
    Counts maps each word to the number of times it appears.

func Count(s string) Counts
func (c Counts) Top(n int) []Entry
func (c Counts) entries() []Entry
```

The first listing is the package's **API**, everything another package can come to depend on. Rename
`Top` and both programs in `cmd` stop compiling, along with anybody else's. Rename `entries`, or
replace it and `byCount` with a different way of sorting, and nothing outside `text` can notice. So
the habit that pays is to **start every name in lower case**, and capitalise it on the day another
package needs it. The fields of `Entry` are capitalised for exactly that reason: `cmd/wordtop`
prints `e.Word` and `e.Count`.

A name the compiler did not need to see is also a name you did not have to document. Every exported
name above carries a comment that starts with the name, which is what `go doc` printed; `entries`
and `byCount` carry none, and nothing asks for one.

## JSON, and every package that reads your fields

Lesson 15 marshalled a struct whose field `age` was missing from the output, and pointed here for
the reason. `json.Marshal` is a function in the package `encoding/json`, which works on your struct
from outside your package and keeps to the same rule: its documentation says that "each exported
struct field becomes a member of the object". A tag does not change that:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type Entry struct {
	Word  string `json:"word"`
	count int    `json:"count"`
}

func main() {
	b, err := json.Marshal(Entry{Word: "go", count: 3})
	fmt.Println(string(b), err)

	var e Entry
	err = json.Unmarshal([]byte(`{"word":"go","count":3}`), &e)
	fmt.Printf("%+v %v\n", e, err)
}
```

```
ana@vm:~/pkgs-json$ go run .
{"word":"go"} <nil>
{Word:go count:0} <nil>
ana@vm:~/pkgs-json$ go vet; echo $?
main.go:10:2: struct field count has json tag but is not exported
1
```

Both directions failed in silence. `Marshal` left `count` out, `Unmarshal` saw `"count":3` in the
input and left the field at 0, and both returned a nil error. `fmt` printed `count:0` all the same:
it looks inside values through the package `reflect`, which lets another package read a lower-case
field but, in the words of `go doc reflect.Value.CanSet`, never change a value "obtained by the use
of unexported struct fields". `go vet` noticed the contradiction: a tag addressed to another
package, on a field that package can never see. That is a second reason to take lesson 4's advice
and run `go vet` before anything else reads the code.

The same rule holds for other packages that work on your types from outside;
`go doc encoding/xml.Marshal` describes its output as "the exported fields of the struct". **If
another package must read or fill a field, the field starts with a capital letter.**
