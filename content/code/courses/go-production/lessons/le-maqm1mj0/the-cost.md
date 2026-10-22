---
title: What reflection costs, and what to write instead
version: 1
---

Reflection has a reputation for being slow, and that reputation is where most people stop thinking
about its cost. **Speed is the smaller of the two costs, and the size of it depends on what surrounds
the reflective code. The larger cost is the compiler's checks, which reflection gives up entirely.**
This section measures the first and shows the second, on the column picker from section 03 and on a
version of it written without `reflect`.

## The same table without reflection

The columns of a `tally.PathCount` are two, and they can be written out by hand: a name, and a
function that prints a row's cell. Made generic over the row type, as in `go` lessons 30 and 31, the
same `Table` serves any row type that somebody gives a column list. In the same package,
`internal/columns/table.go`:

```go
package columns

import (
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
	"text/tabwriter"

	"example.com/hits/internal/tally"
)

// Column is one column a table can show: its name and how to print a row's
// cell in it.
type Column[T any] struct {
	Name string
	Cell func(T) string
}

// PathColumns are the columns of a tally.PathCount, written out by hand.
var PathColumns = []Column[tally.PathCount]{
	{"path", func(r tally.PathCount) string { return r.Path }},
	{"hits", func(r tally.PathCount) string { return strconv.Itoa(r.Hits) }},
}

// Table prints the named columns of rows, taking each one from cols.
func Table[T any](w io.Writer, rows []T, cols []Column[T], names []string) error {
	pick := make([]Column[T], len(names))
	for i, name := range names {
		j := slices.IndexFunc(cols, func(c Column[T]) bool { return c.Name == name })
		if j < 0 {
			return fmt.Errorf("%w %q", ErrUnknown, name)
		}
		pick[i] = cols[j]
	}

	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, strings.Join(names, "\t"))
	cells := make([]string, len(pick))
	for _, r := range rows {
		for i, c := range pick {
			cells[i] = c.Cell(r)
		}
		fmt.Fprintln(tw, strings.Join(cells, "\t"))
	}
	return tw.Flush()
}
```

Nothing here is looked up at run time except the column names a user typed. **`r.Path` and `r.Hits`
are ordinary field accesses, so the compiler checks them**, and `Table` cannot be handed anything but
a slice of the type its columns were written for. A test that the two versions print the same bytes,
and benchmarks for both, plus three ways of reading one field with nothing around them, in
`internal/columns/columns_test.go`:

```go
package columns

import (
	"bytes"
	"io"
	"reflect"
	"testing"

	"example.com/hits/internal/tally"
)

// rows are the eight paths of the 20,000-line log, as tally.Top returns them.
var rows = tally.Top(tally.Summary{ByPath: map[string]int{
	"/login": 2576, "/api/orders": 2542, "/static/app.js": 2526, "/api/users": 2512,
	"/api/orders/42": 2503, "/static/app.css": 2490, "/": 2487, "/health": 2364,
}}, 8)

var names = []string{"path", "hits"}

func TestSameTable(t *testing.T) {
	var a, b bytes.Buffer
	if err := Reflect(&a, rows, names); err != nil {
		t.Fatal(err)
	}
	if err := Table(&b, rows, PathColumns, names); err != nil {
		t.Fatal(err)
	}
	if a.String() != b.String() {
		t.Errorf("Reflect printed\n%s\nTable printed\n%s", a.String(), b.String())
	}
}

func BenchmarkReflect(b *testing.B) {
	for b.Loop() {
		Reflect(io.Discard, rows, names)
	}
}

func BenchmarkTable(b *testing.B) {
	for b.Loop() {
		Table(io.Discard, rows, PathColumns, names)
	}
}

// The three ways to read one field, without a table around them.
var sum int

func BenchmarkFieldDirect(b *testing.B) {
	for b.Loop() {
		for _, r := range rows {
			sum += r.Hits
		}
	}
}

func BenchmarkFieldIndex(b *testing.B) {
	v := reflect.ValueOf(rows)
	for b.Loop() {
		for i := range v.Len() {
			sum += int(v.Index(i).Field(1).Int())
		}
	}
}

func BenchmarkFieldByName(b *testing.B) {
	v := reflect.ValueOf(rows)
	for b.Loop() {
		for i := range v.Len() {
			sum += int(v.Index(i).FieldByName("Hits").Int())
		}
	}
}
```

The benchmarks use the `b.Loop` form `go-concurrency` lesson 29 taught, and `-count=3` runs each one
three times so that the spread is visible:

```
ana@vm:~/reflect-hits$ go vet ./... && go test -count=1 ./internal/columns
ok  	example.com/hits/internal/columns	0.002s
ana@vm:~/reflect-hits$ go test -run "^$" -bench . -benchmem -count=3 ./internal/columns
goos: linux
goarch: amd64
pkg: example.com/hits/internal/columns
cpu: Intel(R) Xeon(R) Processor
BenchmarkReflect-4       	  293695	      4665 ns/op	    2272 B/op	      58 allocs/op
BenchmarkReflect-4       	  282636	      4909 ns/op	    2272 B/op	      58 allocs/op
BenchmarkReflect-4       	  268616	      4475 ns/op	    2272 B/op	      58 allocs/op
BenchmarkTable-4         	  348522	      3985 ns/op	    2072 B/op	      50 allocs/op
BenchmarkTable-4         	  366930	      4382 ns/op	    2072 B/op	      50 allocs/op
BenchmarkTable-4         	  339334	      3976 ns/op	    2072 B/op	      50 allocs/op
BenchmarkFieldDirect-4   	72886593	        15.37 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldDirect-4   	77271601	        15.47 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldDirect-4   	73453356	        15.37 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31072404	        39.80 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31684237	        38.74 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31851861	        37.52 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 3184506	       376.3 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 2936642	       393.2 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 3161532	       409.6 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/hits/internal/columns	19.102s
```

The timings move from run to run on a shared machine, and the third digit means nothing. **What holds
across the three runs is the ratios and the allocation counts**:

| benchmark | ns/op, three runs | against direct | allocations |
|---|---|---|---|
| `FieldDirect`, `r.Hits` | 15.37 to 15.47 | 1 | 0 |
| `FieldIndex`, `Index(i).Field(1).Int()` | 37.52 to 39.80 | about 2.5 times | 0 |
| `FieldByName`, `FieldByName("Hits")` | 376.3 to 409.6 | about 25 times | 0 |
| `Table`, the whole table | 3976 to 4382 | | 50 |
| `Reflect`, the whole table | 4475 to 4909 | | 58 |

Reading a field by its index costs a few nanoseconds more than reading it directly, because every
call checks the kind and works out the field's address. **Reading it by name is ten times worse again**, since
`FieldByName` walks the struct's fields comparing strings and builds a full `StructField` for the
match, on every call. That is why `columns.Reflect` turns each name into an index once, before the
loop, and why `encoding/json` keeps its list of fields per type. Code that calls `FieldByName` inside a
loop pays the 25 times on every row.

**Around a whole table the gap shrinks to about a sixth**, 4665 ns against 3985 taking the median
of each three, because most of the time goes on `tabwriter`, `strings.Join` and
writing, which both versions share. `Reflect` also made 8 more allocations and 200 more bytes per
table, 58 against 50. In `hits`, where `tally.Count` spends far longer reading 20,000 lines than
either version spends printing eight rows, nobody would notice the difference without a benchmark.
Lessons 12 and 13 are where a profile says whether a cost like this is the one worth removing.

## The checks that were given away

The cost that would be noticed is a mistake that compiles. Suppose somebody decides `cols` should
print only the busiest path and adds `[0]` to the call in `cmd/cols/main.go`:

```
ana@vm:~/reflect-hits$ sed -i "s/tally.Top(s, \*n)/tally.Top(s, *n)[0]/" cmd/cols/main.go
ana@vm:~/reflect-hits$ go vet ./... && go build -o cols ./cmd/cols && ./cols access.log; echo $?
cols: columns: want a slice of structs, got tally.PathCount
1
```

`go vet` and the compiler had nothing to say, because a `tally.PathCount` is a perfectly good `any`.
**The mistake surfaced when the program ran, and only because `Reflect` checks for a slice and
returns an error**; without that check it would have been a panic. Now a typo in the version without
reflection:

```
ana@vm:~/reflect-hits$ sed -i "s/r.Hits)/r.Hist)/" internal/columns/table.go
ana@vm:~/reflect-hits$ go build ./...
# example.com/hits/internal/columns
internal/columns/table.go:24:66: r.Hist undefined (type tally.PathCount has no field or method Hist)
```

That one never reached a binary. Both edits undone, and the command back to lesson 1's numbers:

```
ana@vm:~/reflect-hits$ sed -i "s/r.Hist)/r.Hits)/" internal/columns/table.go
ana@vm:~/reflect-hits$ sed -i "s/tally.Top(s, \*n)\[0\]/tally.Top(s, *n)/" cmd/cols/main.go
ana@vm:~/reflect-hits$ go build -o cols ./cmd/cols && ./cols -n 1 access.log
path    hits
/login  2576
```

Tags have the same weakness one level down. `go vet` checks a tag's syntax, as `go` lesson 15
showed, and, as section 03 showed, a tag on an unexported field. **It cannot check a tag's meaning**:
rename `json:"hits"` to `json:"hist"` in `tally` and everything still compiles, `hits top -json` starts
printing a different key, and the first sign is a dashboard that goes blank somewhere else. Renaming
a field with an editor's refactoring tool fixes every `r.Hits`; it does not touch a string.

## When reflection is the right tool

None of this makes reflection wrong. **It is right when the types are not known to the code at all
until it runs**, because they belong to somebody else, and the standard library is the place to see
which code that is:

```
ana@vm:~/reflect-hits$ go list -f "{{.ImportPath}} {{range .Imports}}{{if eq . \"reflect\"}}imports reflect{{end}}{{end}}" encoding/json fmt flag text/template strconv slices
encoding/json imports reflect
fmt imports reflect
flag imports reflect
text/template imports reflect
strconv 
slices 
```

`encoding/json` serialises structs it has never seen, `fmt` prints them, `text/template` calls
their methods by the names in a template, and `flag` reflects to work out a flag's zero value, which
is how lesson 1's `-h` knew to print `(default 3)` for `-n` and nothing for `-json`. `strconv` and
`slices` work on types they know or take as type parameters, and need none of it. In tests,
`reflect.DeepEqual` compares two values of any type field by field, unexported fields included,
which is exactly what a test helper wants and what ordinary code cannot write for a type it does not
know.

| situation | reach for |
|---|---|
| a library that must handle types its callers will write later: an encoder, a printer, a test helper | `reflect`, behind a small API that returns errors instead of panicking |
| one algorithm over many types, all known where it is called | generics, `go` lessons 30 and 31 |
| a few known types, and the per-type code is boring and repetitive | code generation, lesson 10: a generator run by `go generate` can write the `PathColumns` lists, and the compiler checks what it wrote |
| one type, one place | plain code |

**For `hits`, `Table` is the better choice**: one row type, two columns, every field access
checked, and a little faster. `columns.Reflect` would earn its place in a package that printed the
rows of other people's structs, which is the situation `encoding/json` is in and `hits` is not.
Lesson 22 opens the next hatch, `unsafe`.
