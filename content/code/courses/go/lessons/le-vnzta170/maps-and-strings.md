---
title: Walking maps and strings
version: 1
---

`range` works on more than slices, and each kind of value decides what the two variables hold. A
map hands you a **key** and its value, where a slice handed you an index. A string hands you a
**byte offset** and a rune, which is the one that surprises people, and it is the second half of
this section.

## Maps: key, value, and no order

Lesson 14 ran the same map walk twice and got two different orders.
That is the first thing to know about `for key, value := range m`: **the order is not yours to rely on.** Everything else about
walking a map follows from it. This program walks one map in three ways:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"maps\"\n\t\"slices\"\n)\n\nfunc main() {\n\tstock := map[string]int{\"apples\": 3, \"pears\": 0, \"plums\": 7, \"figs\": 0}\n\n\tfor fruit, n := range stock {\n\t\tif n == 0 {\n\t\t\tdelete(stock, fruit)\n\t\t}\n\t}\n\tfmt.Println(stock)\n",
      "note": "**Deleting entries while you walk a map is allowed.** The fruits that ran out are gone, whatever order the walk took. `fmt.Println` prints a map with its keys sorted, as lesson 14 warned, so this line comes out the same on every run."
    },
    {
      "code": "\n\tfor _, fruit := range slices.Sorted(maps.Keys(stock)) {\n\t\tfmt.Println(fruit, stock[fruit])\n\t}\n",
      "note": "When the order matters, walk a sorted slice of the keys. This is lesson 14's technique, with `range` over the slice doing what an index did there."
    },
    {
      "code": "\n\ttotal := 0\n\tfor n := range maps.Values(stock) {\n\t\ttotal += n\n\t}\n\tfmt.Println(\"total\", total)\n}\n",
      "note": "`maps.Values` returns an **iterator**, a function that hands out the values one at a time, and `range` accepts it directly. A sum does not care about order, so the map's own order is fine here."
    }
  ],
  "output": "map[apples:3 plums:7]\napples 3\nplums 7\ntotal 10"
}
```

Adding entries during a walk is the other half of the rule, and it is weaker. An entry created
while the loop runs may be visited or may be skipped, and the language specification leaves the
choice open. Build
the new entries in a second map and copy them over when the loop is done.

The last loop needs a word more. `go doc maps.Keys` in lesson 14 showed a return type of
`iter.Seq[K]`, which is the type of such a function. Before Go 1.23, `range` could not call one:

```
ana@vm:~/loops-map$ go mod edit -go=1.22 && go run .
# example.com/loops-map
./main.go:24:17: cannot range over maps.Values(stock) (value of func type iter.Seq[int]): requires go1.23 or later (-lang was set to go1.22; check go.mod)
```

Writing an iterator of your own needs function values, the subject of lesson 21. Ranging over the
ones the standard library returns takes nothing more than you have just seen.

## Strings: byte offsets and runes

Lesson 9 showed that `s[i]` is a byte, and that slicing a string by counting characters goes wrong
outside ASCII. **`range` over a string decodes the UTF-8 for you**: on every pass it gives the byte
offset where a rune starts, and the rune. This program puts the two ways of walking a string side
by side, on a string with an `é` and one byte that is not UTF-8 at all:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\ts := \"café\\xff!\"\n\n\tfor i, r := range s {\n\t\tfmt.Printf(\"%d %U\\n\", i, r)\n\t}\n",
      "note": "**The first variable is a byte offset, not a count of characters.** It goes 0, 1, 2, 3 and then 5, because the `é` at offset 3 took two bytes. `\\xff` begins no character, so `range` hands back U+FFFD, the replacement character, and moves on by a single byte, to the `!` at 6."
    },
    {
      "code": "\n\tfmt.Println(len(s))\n\tfor i := 0; i < len(s); i++ {\n\t\tfmt.Printf(\"%d %x\\n\", i, s[i])\n\t}\n}\n",
      "note": "Indexing with a three-clause loop walks the 7 bytes instead. `c3 a9` is the `é`, as lesson 8 printed it, and `ff` is the broken byte, passed through untouched."
    }
  ],
  "output": "0 U+0063\n1 U+0061\n2 U+0066\n3 U+00E9\n5 U+FFFD\n6 U+0021\n7\n0 63\n1 61\n2 66\n3 c3\n4 a9\n5 ff\n6 21"
}
```

Six passes against seven bytes. Neither loop is wrong: the byte loop is the right one for a file
format or a checksum, and the `range` loop for anything that treats the string as text.

The U+FFFD needs a careful reading, because `range` did not fail on the broken byte. It produced a
perfectly good rune, the same one the standard library names as its error value:

```
ana@vm:~/loops-string$ go doc unicode/utf8.RuneError | grep 'RuneError ='
	RuneError = '\uFFFD'     // the "error" Rune or "Unicode replacement character"
```

So a program that copies text rune by rune with `range` turns every broken byte into a valid U+FFFD,
and from then on nobody can tell the text was ever broken. **When a string comes from outside your
program and its correctness matters, check it with `utf8.ValidString` before the loop**, as lesson
9 advised, rather than looking for the damage afterwards.

## What `range` gives, by kind

| you range over | the first variable | the second variable |
|---|---|---|
| an integer `n` | 0 to `n`-1 | none |
| a slice or an array | the index | a copy of the element |
| a string | the byte offset where a rune starts | the rune |
| a map | the key | a copy of the value |
| an iterator such as `maps.Values(m)` | what the iterator hands out | for some iterators, a second value |

Channels can be ranged over as well. They belong to the `go-concurrency` course, along with the
goroutines that send on them.
