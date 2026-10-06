---
title: A struct goes out as JSON
version: 1
---

`encoding/json` turns a Go value into JSON with `json.Marshal`, and for a struct the result is a
JSON object with a key per field. The wrong expectation is that it writes *every* field. **It writes
the exported fields, the ones whose names start with a capital letter, and leaves the rest out
without a word.** Here is a `User` with no instructions at all:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name     string
	Email    string
	Password string
	Tags     []string
	age      int
}

func main() {
	u := User{Name: "Ana", Password: "hunter2", age: 31}
	b, err := json.Marshal(u)
	fmt.Println(string(b), err)
}
```

```
ana@vm:~/structs-json-plain$ go run .
{"Name":"Ana","Email":"","Password":"hunter2","Tags":null} <nil>
```

`Marshal` returns the JSON as a `[]byte` and an error, and `<nil>` means there was none; lesson 32
is about errors. Four things in that one line are worth reading:

- the keys are the Go field names, capital letters and all, because nothing said otherwise;
- the empty `Email` was written as `""`, since an empty string is still a string;
- **the password went out**, which is the line that ends up in a log nobody meant to keep;
- `age` is not there at all, and `err` is still nil.

The last one surprises everybody once. `json.Marshal` lives in another package, and a name that
starts with a lower-case letter cannot be seen from another package. Lesson 4 mentioned the capital
letter and lesson 39 is about it. Because of that rule, a field you meant to send but named in lower
case is missing from the output, and no compiler, no vet check and no error tells you. `Tags` came
out as `null` because it was a nil slice, the distinction lesson 12 pointed at.

## Tags: instructions written on the field

A **struct tag** is a string written after a field's type, and `encoding/json` reads the part of it
under the key `json`. The same `User`, with tags:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n)\n\ntype User struct {\n\tName     string   `json:\"name\"`\n",
      "note": "**The first word of a json tag is the key to use**, so `Name` goes out as `name`. A tag is a raw string literal, lesson 9's backquotes, because it is full of double quotes."
    },
    {
      "code": "\tEmail    string   `json:\"email,omitempty\"`\n",
      "note": "**`omitempty` leaves the field out when it is empty**: `false`, `0`, a nil pointer or interface, or an array, slice, map or string of length zero."
    },
    {
      "code": "\tPassword string   `json:\"-\"`\n",
      "note": "**A tag of `-` keeps the field out of the JSON always**, empty or not. This is how a field that must never leave the program is marked."
    },
    {
      "code": "\tTags     []string `json:\"tags\"`\n\tage      int\n}\n",
      "note": "`tags` has a name and no option, so a nil slice still goes out as `null`. `age` needs no tag to stay out; it stays out because of its first letter."
    },
    {
      "code": "\nfunc main() {\n\tu := User{Name: \"Ana\", Password: \"hunter2\", age: 31}\n\tb, err := json.Marshal(u)\n\tfmt.Println(string(b), err)\n\n\tu.Email = \"ana@example.com\"\n\tu.Tags = []string{\"go\", \"sql\"}\n\tb, err = json.MarshalIndent(u, \"\", \"  \")\n\tfmt.Println(string(b), err)\n}\n",
      "note": "The same value twice: once with `Email` empty, once filled in. `json.MarshalIndent` is `Marshal` with line breaks, indenting each level by its last argument, here two spaces."
    }
  ],
  "output": "{\"name\":\"Ana\",\"tags\":null} <nil>\n{\n  \"name\": \"Ana\",\n  \"email\": \"ana@example.com\",\n  \"tags\": [\n    \"go\",\n    \"sql\"\n  ]\n} <nil>"
}
```

The first line has no `email`, because it was empty and the tag said so, and no `Password`, because
the tag said never. The second has `email` back. The picture is the whole section in one place:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The struct User has five fields. Name, tagged json name, is written as the key name. Email, tagged json email omitempty, is written as the key email only when it is not empty. Password, tagged json dash, is never written. Tags, tagged json tags, is written as the key tags, and a nil slice comes out as null. The field age starts with a lower-case letter, so json.Marshal cannot see it and leaves it out without saying so.\"><defs><marker id=\"js-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"156.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the struct, in Go</text><text x=\"562.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what json.Marshal writes</text><rect x=\"16\" y=\"42\" width=\"280\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Name string `json:&quot;name&quot;`</text><rect x=\"420\" y=\"54.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;name&quot;: &quot;Ana&quot;</text><path d=\"M302 67.0 L414 67.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#js-phosphor)\"></path><text x=\"28\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Email string `json:&quot;email,omitempty&quot;`</text><rect x=\"420\" y=\"88.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"432\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;email&quot;: &quot;...&quot;</text><path d=\"M302 101.0 L414 101.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#js-phosphor)\"></path><text x=\"694\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only when it is not empty</text><text x=\"28\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Password string `json:&quot;-&quot;`</text><path d=\"M302 135.0 L340 135.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340 126.0 L340 144.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">never: the tag is &quot;-&quot;</text><text x=\"28\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Tags []string `json:&quot;tags&quot;`</text><rect x=\"420\" y=\"156.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;tags&quot;: null</text><path d=\"M302 169.0 L414 169.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#js-phosphor)\"></path><text x=\"694\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a nil slice is null</text><text x=\"28\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">age int</text><path d=\"M302 203.0 L340 203.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340 194.0 L340 212.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">never, and nothing says so: lower case</text></svg>", "caption": "Five fields go in and three keys can come out. The tag decides the name and whether a field is written at all; the first letter of the field's name decides whether encoding/json can see it."}
```

## The compiler does not read tags

A tag is an ordinary string as far as the compiler is concerned. **A typo in a tag compiles, runs,
and is ignored**, so the field quietly goes back to its default behaviour:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string `json: "name"`
	Email string `json:"email, omitempty"`
}

func main() {
	b, _ := json.Marshal(User{Name: "Ana"})
	fmt.Println(string(b))
}
```

```
ana@vm:~/structs-tags-bad$ go run .
{"Name":"Ana","email":""}
ana@vm:~/structs-tags-bad$ go vet; echo $?
main.go:9:2: struct field tag `json: "name"` not compatible with reflect.StructTag.Get: bad syntax for struct tag value
main.go:10:2: struct field tag `json:"email, omitempty"` not compatible with reflect.StructTag.Get: suspicious space in struct tag value
1
```

One space in each tag. In the first, after the colon, the whole tag is unreadable, so `Name` went
out under its Go name. In the second, before `omitempty`, the option became ` omitempty` with a
leading space, which is no option at all, so the empty email was written. `go run` was happy with
both; `go vet` found both. That is lesson 4's advice again with a sharper reason: **run `go vet`
on anything with struct tags**, because it is the only tool here that reads them before
`encoding/json` does.

## `omitempty` and `omitzero`

`omitempty` has a gap, and a type from the standard library falls straight into it. The time of
day is a struct, `time.Time`, and a struct is never "empty" by that definition, however zero it is:

```go
package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Event struct {
	Name    string    `json:"name"`
	Retries int       `json:"retries,omitempty"`
	Started time.Time `json:"started,omitempty"`
	Ended   time.Time `json:"ended,omitzero"`
}

func main() {
	b, _ := json.Marshal(Event{Name: "deploy"})
	fmt.Println(string(b))
}
```

```
ana@vm:~/structs-omitzero$ go run .
{"name":"deploy","started":"0001-01-01T00:00:00Z"}
```

`Retries` was 0 and `omitempty` dropped it. `Started` was the zero `time.Time` and `omitempty` wrote
it anyway, as the first instant of year 1, which a reader will take for a real date. `Ended` had the
same zero value and **`omitzero` dropped it, because it leaves a field out when it holds its type's
zero value, whatever the type is.** The documentation of `json.Marshal` in go1.27.1 also says that
when the type has an `IsZero() bool` method, as `time.Time` does, `omitzero` asks it. For a field of
a struct type, `omitzero` is the one that does what the name of the other promises.
