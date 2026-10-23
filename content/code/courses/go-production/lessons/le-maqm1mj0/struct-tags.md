---
title: Struct tags, read the way encoding/json reads them
version: 1
---

A struct tag is the string in backquotes after a field, and **the compiler stores it and never looks
inside it**. It has no effect on the program until something reads it at run time, and the only way
to read it is reflection. `go` lesson 15 wrote `json:"name"` tags and `go-concurrency` lesson 19
used `omitempty`; this section reads the same tags from the other side, as the encoder does, and
then builds something of its own on them for `hits`.

## Get, Lookup and the field's description

`reflect.Type` describes each field with a `StructField`: its name, its type, whether it is
exported, and its `Tag`, of type `StructTag`. `Tag.Get("json")` returns the value under one key, and
`Tag.Lookup` returns it with a second result saying whether the key was there at all. A struct
with one field for each case a `json` tag can be in, then `encoding/json` asked about the same struct,
in `tags/main.go`:

```go
// Command tags reads a struct's tags the way encoding/json does, and then
// asks encoding/json for its own answer.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"time"
)

// Row has one field for each case a json tag can be in.
type Row struct {
	Path    string        `json:"path"`
	Hits    int           `json:"hits,omitempty"`
	Total   time.Duration `json:"-"`
	Method  string        `json:",omitempty"`
	Status  int
	comment string `json:"comment"`
}

func main() {
	t := reflect.TypeFor[Row]()
	for f := range t.Fields() {
		tag, ok := f.Tag.Lookup("json")
		fmt.Printf("%-8s exported=%-5t json=%-18q present=%t\n", f.Name, f.IsExported(), tag, ok)
	}

	r := Row{Path: "/login", Total: time.Second, Method: "GET", Status: 200, comment: "busy"}
	out, err := json.Marshal(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(string(out))

	c := reflect.ValueOf(r).FieldByName("comment")
	fmt.Printf("comment: %q, CanInterface=%t\n", c.String(), c.CanInterface())
	fmt.Println(c.Interface())
}
```

`reflect.TypeFor[Row]()` is `TypeOf` for when you have the type and no value. Run, with the last
line making a mistake on purpose:

```
ana@vm:~/reflect$ go run ./tags
Path     exported=true  json="path"             present=true
Hits     exported=true  json="hits,omitempty"   present=true
Total    exported=true  json="-"                present=true
Method   exported=true  json=",omitempty"       present=true
Status   exported=true  json=""                 present=false
comment  exported=false json="comment"          present=true
{"path":"/login","Method":"GET","Status":200}
comment: "busy", CanInterface=false
panic: reflect.Value.Interface: cannot return value obtained from unexported field or method

goroutine 1 [running]:
reflect.valueInterface({0x64ac58?, 0x533ae0?, 0x527549?}, 0x1d?)
	/usr/local/go/src/reflect/value.go:1501 +0xde
reflect.Value.Interface(...)
	/usr/local/go/src/reflect/value.go:1490
main.main()
	/home/ana/reflect/tags/main.go:40 +0x2f0
exit status 2
```

**Every decision in the JSON line can be read off the table above it.** `Path` went out as `path`,
the name in its tag. `Hits` has `omitempty` and holds 0, so it was left out. `Total` is tagged `-`,
which means never. `Method`'s tag is present but its name is empty, so the field kept its own name,
and `Status` has no tag at all, which `Lookup` reports as `present=false` and `Get` cannot tell
apart from an empty one. `comment` is not exported, and nothing of it reached the output.

This is the encoder's own code, a few lines into the function that builds its list of fields:

```
ana@vm:~/reflect$ sed -n 1133,1141p /usr/local/go/src/encoding/json/encode.go
				} else if !sf.IsExported() {
					// Ignore unexported non-embedded fields.
					continue
				}
				tag := sf.Tag.Get("json")
				if tag == "-" {
					continue
				}
				name, opts := parseTag(tag)
```

`!sf.IsExported()`, `sf.Tag.Get("json")`, `tag == "-"`: the same calls `tags/main.go` made. **There
is no magic in `encoding/json` beyond reflection**, and once it has worked out the list for a type it
keeps it, so the tags are read once per type rather than once per value.

## What an unexported field allows

The wrong idea here is that reflection cannot see an unexported field. It can: `comment` is in the
table, and `c.String()` read `"busy"` out of it. **What reflection refuses is to let the value leave
as an `any`, or to change it.** `CanInterface` says false, and `Interface` panicked with the
sentence above. The reason is the package boundary from `go` lesson 39. If any package could take an
unexported field out as an `any`, or set it, a lower-case name would protect nothing, so the rule
holds for reflection too. Section 04 shows the refusal to set.

**A tag on an unexported field is therefore a mistake, and `go vet` knows it:**

```
ana@vm:~/reflect$ go vet ./tags
tags/main.go:20:2: struct field comment has json tag but is not exported
```

## A column picker for `hits`

Lesson 1's `hits top -json` prints `path` and `hits`, the names in `tally.PathCount`'s tags. A small
command that prints chosen columns of that table by the same names is a realistic job for
reflection. The names a user types are the names in the tags, and the code that finds them knows
nothing about `PathCount`. It lives in a new module, `~/reflect-hits`, made with
`go mod init example.com/hits`, holding the `tally` package from lesson 1 (`internal/tally/tally.go`),
its `tools/genlog`, and an `access.log` written by lesson 1's
`go run ./tools/genlog -n 20000 > access.log`. The new package is `internal/columns/columns.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/columns/columns.go",
  "parts": [
    {
      "code": "// Package columns prints chosen fields of a slice of structs as a table,\n// naming each field the way encoding/json would.\npackage columns\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"reflect\"\n\t\"strconv\"\n\t\"strings\"\n\t\"text/tabwriter\"\n)\n\n// ErrUnknown is returned for a column name no field answers to.\nvar ErrUnknown = errors.New(\"unknown column\")\n",
      "note": "A sentinel error, so the command can tell a column nobody has from a write that failed (lesson 1's 2 against 1)."
    },
    {
      "code": "// Reflect prints the named columns of rows, which must be a slice of\n// structs. It finds each column by reading the struct's json tags.\nfunc Reflect(w io.Writer, rows any, names []string) error {\n\tv := reflect.ValueOf(rows)\n\tif v.Kind() != reflect.Slice || v.Type().Elem().Kind() != reflect.Struct {\n\t\treturn fmt.Errorf(\"columns: want a slice of structs, got %T\", rows)\n\t}",
      "note": "**`rows any` accepts anything, so the check the compiler would have made is made here, at run time**: a slice, of structs. `%T` names whatever came instead."
    },
    {
      "code": "\tt := v.Type().Elem()\n\tindex := make([]int, len(names))\n\tfor i, name := range names {\n\t\tj, ok := fieldNamed(t, name)\n\t\tif !ok {\n\t\t\treturn fmt.Errorf(\"%w %q: %v has no such field\", ErrUnknown, name, t)\n\t\t}\n\t\tindex[i] = j\n\t}\n",
      "note": "Each name is looked up once, before any row is printed, and turned into a field index. A name nobody answers to fails here, with the type in the message."
    },
    {
      "code": "\ttw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, strings.Join(names, \"\\t\"))\n\tcells := make([]string, len(index))\n\tfor r := range v.Len() {\n\t\trow := v.Index(r)\n\t\tfor i, j := range index {\n\t\t\tcells[i] = text(row.Field(j))\n\t\t}\n\t\tfmt.Fprintln(tw, strings.Join(cells, \"\\t\"))\n\t}\n\treturn tw.Flush()\n}\n",
      "note": "The loop reads every row through `Index` and every cell through `Field(j)`, by position. Nothing in it knows that the rows are `tally.PathCount`."
    },
    {
      "code": "// fieldNamed finds the field encoding/json would call name: the name in its\n// json tag, or its own name when the tag gives none. A field that is not\n// exported, or is tagged \"-\", has no name at all.\nfunc fieldNamed(t reflect.Type, name string) (int, bool) {\n\tfor f := range t.Fields() {\n\t\ttag := f.Tag.Get(\"json\")\n\t\tif !f.IsExported() || tag == \"-\" {\n\t\t\tcontinue\n\t\t}\n\t\tn, _, _ := strings.Cut(tag, \",\")\n\t\tif n == \"\" {\n\t\t\tn = f.Name\n\t\t}\n\t\tif n == name {\n\t\t\treturn f.Index[0], true\n\t\t}\n\t}\n\treturn 0, false\n}\n",
      "note": "**The rule `encoding/json` applies, written out**: skip what is unexported or tagged `-`, take the tag's name up to the first comma, and fall back to the field's own name when the tag gives none."
    },
    {
      "code": "// text formats one cell. The kinds a log's rows hold get their own\n// conversion; anything else goes through fmt.\nfunc text(v reflect.Value) string {\n\tswitch v.Kind() {\n\tcase reflect.String:\n\t\treturn v.String()\n\tcase reflect.Int, reflect.Int64:\n\t\treturn strconv.FormatInt(v.Int(), 10)\n\t}\n\treturn fmt.Sprint(v.Interface())\n}",
      "note": "A switch on `Kind`, the way `encoding/json` picks an encoder: a string and an integer are converted directly, and anything else goes through `fmt`, which reflects on it again."
    }
  ]
}
```

And a command in front of it, which counts the log with `tally` and hands the rows to
`columns.Reflect`, in `cmd/cols/main.go`:

```go
// Command cols prints chosen columns of the busiest paths in an access log.
package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"

	"example.com/hits/internal/columns"
	"example.com/hits/internal/tally"
)

func main() {
	fields := flag.String("fields", "path,hits", "columns to print, by their json names")
	n := flag.Int("n", 3, "how many paths to show")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: cols [-fields a,b] [-n N] file")
		os.Exit(2)
	}
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()
	s, err := tally.Count(f)
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
	err = columns.Reflect(os.Stdout, tally.Top(s, *n), strings.Split(*fields, ","))
	if errors.Is(err, columns.ErrUnknown) {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
}
```

Built, asked for the default columns, then for the two in the other order and five rows, then
twice for a column that does not exist:

```
ana@vm:~/reflect-hits$ go build -o cols ./cmd/cols && ./cols access.log
path            hits
/login          2576
/api/orders     2542
/static/app.js  2526
ana@vm:~/reflect-hits$ ./cols -fields hits,path -n 5 access.log
hits  path
2576  /login
2542  /api/orders
2526  /static/app.js
2512  /api/users
2503  /api/orders/42
ana@vm:~/reflect-hits$ ./cols -fields path,hist access.log; echo $?
cols: unknown column "hist": tally.PathCount has no such field
2
ana@vm:~/reflect-hits$ ./cols -fields Hits access.log; echo $?
cols: unknown column "Hits": tally.PathCount has no such field
2
```

The counts are lesson 1's, `/login` with 2576 first. **`Hits` is refused although the Go field is
called `Hits`**, because the rule `fieldNamed` copies says a tag's name replaces the field's, and the
tag says `hits`. Both refusals exit 2, the code lesson 1 gives a caller's mistake, because the
command could tell `ErrUnknown` apart from a failed write.

**Nothing in `Reflect` names `PathCount`, and that is what reflection bought**: hand it a slice of any
struct with tags and it prints those columns too. It also cost something that the transcript cannot
show yet. `Reflect` takes `rows any`, so the compiler accepts any value at all there, and the check it
would have made now happens on every call, at run time. Section 05 measures that cost and the speed
one beside it.
