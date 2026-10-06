---
title: Declaring a sentinel of your own
version: 1
---

A sentinel belongs to a package, and it only earns its keep when code in another package checks
for it. So this example is a module, `example.com/shop`, with a package `store` in a directory of
its own and a `main` that uses it. The store sells apples and pears, and asking for anything else
is the failure its callers are meant to recognise:

```schooling-example
{
  "language": "go",
  "file": "store/store.go",
  "parts": [
    {
      "code": "// Package store keeps the shop's stock in memory.\npackage store\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n)\n\n",
      "note": "A package of its own, in the directory `store` of the module `example.com/shop`. Lesson 39 is about packages; here it is enough that `main` imports this one by that path."
    },
    {
      "code": "// ErrNotFound means the store does not sell the item asked for.\nvar ErrNotFound = errors.New(\"not found\")\n\n",
      "note": "**The sentinel: an exported variable, made once, whose name starts with `Err`.** The comment above it is what `go doc` prints, and it says what the error means, which is the part a caller relies on."
    },
    {
      "code": "var stock = map[string]int{\"apple\": 12, \"pear\": 0}\n\n",
      "note": "The stock is unexported, so nothing outside the package can see it. `pear` is in it with 0: having none is an answer, not an error."
    },
    {
      "code": "// Count reports how many of an item are in stock. For an item the store\n// does not sell, the error wraps ErrNotFound.\nfunc Count(item string) (int, error) {\n\tn, ok := stock[item]\n\tif !ok {\n\t\treturn 0, fmt.Errorf(\"count %q: %w\", item, ErrNotFound)\n\t}\n\treturn n, nil\n}\n",
      "note": "**`Count` wraps the sentinel with `%w` and adds the item's name**, and its comment says which sentinel to look for. The message gains the detail a person needs; the chain keeps the value a program checks."
    }
  ]
}
```

The program asks about three items and **branches on the sentinel with `errors.Is`**, because
`Count` returns it wrapped:

```go
func main() {
	for _, item := range []string{"apple", "pear", "plum"} {
		n, err := store.Count(item)
		switch {
		case errors.Is(err, store.ErrNotFound):
			fmt.Printf("%s: not sold here (%v)\n", item, err)
		case err != nil:
			fmt.Printf("%s: failed: %v\n", item, err)
		default:
			fmt.Printf("%s: %d in stock\n", item, n)
		}
	}
}
```

```
ana@vm:~/sentinel-store$ go run .
apple: 12 in stock
pear: 0 in stock
plum: not sold here (count "plum": not found)
```

Three answers, and the second one matters as much as the third. A pear count of 0 came back with a
`nil` error: none in stock is a perfectly good answer, and an error would have made every caller
handle it as a failure. `plum` is the case the sentinel exists for. **The message names the item,
because a person reading a log needs it, and the chain still holds `store.ErrNotFound`, because
the program needs that.** Wrapping gave each reader its own half. `err == store.ErrNotFound` would
have been `false` for `plum`, for the reason lesson 34 showed: the value `Count` returned is the
wrapper.

The `case err != nil` line is not decoration either. `Count` cannot fail any other way today, and a
caller that branches on one sentinel still has to do something with every error it does not
recognise.

## The sentinel is part of what the package says

`go doc` prints the sentinel beside the function, which is where a caller looks:

```
ana@vm:~/sentinel-store$ go doc ./store
package store // import "example.com/shop/store"

Package store keeps the shop's stock in memory.

var ErrNotFound = errors.New("not found")
func Count(item string) (int, error)
ana@vm:~/sentinel-store$ go doc ./store Count
package store // import "example.com/shop/store"

func Count(item string) (int, error)
    Count reports how many of an item are in stock. For an item the store does
    not sell, the error wraps ErrNotFound.

```

Two things together make the sentinel usable. The variable is exported, so other packages can
name it, and **the comment on `Count` says which sentinel it returns and when**, because the
signature only says `error`. Lesson 32 made the same observation about `os.Open`, whose
documentation names the type its error will have. Without that sentence a caller has to read the
source to find out what is worth checking, and the source is free to change.

A few habits from the standard library, all visible above and in section 02's list:

- the variable is declared once, at package level, with `errors.New`, and never reassigned;
- its message is short, lower case and without a full stop, like every message in lesson 33,
  because it ends up at the right-hand end of somebody else's sentence: `count "plum": not found`;
- its comment says what the error means, not how it is made.

What `store` has now done is promise something to every program that checks for
`store.ErrNotFound`. Section 04 is about when a package should make that promise, and what it
costs to take one back.
