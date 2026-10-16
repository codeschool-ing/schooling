---
title: Changing the schema
version: 1
---

**Add fields with new numbers, never change what a number means, and reserve the number of a field
you remove.** Those three rules are most of it, and they follow from the fact the earlier sections
kept pointing at: the bytes carry numbers, and each reader brings its own names. A server and its
clients are upgraded on different days, so for a while every change is read by somebody holding the
old `.proto`.

The wrong idea comes from JSON again: that **renaming** a field is the dangerous change and
**renumbering** is a detail. It is the other way round. A new name with the old number sends exactly
the same bytes, and an old client reads them perfectly. The same name with a new number is, on the
wire, a field removed and a different one added.

## The warehouse's next release

The warehouse decides that a book's title belongs to the catalogue, not to the stock, and that a
till would rather know where on the shelves a book is. Its next `StockLevel` drops `title` and adds
`location`. Only that message changes, so the file below holds only that message and the enum it
uses. Save it as `next/stock.proto`, in a directory of its own so that it does not replace the
first one:

```
// shelf/next/stock.proto
// StockLevel as the warehouse's next release sends it. Nothing else changes.
syntax = "proto3";

package shelf.stock.v1;

enum Availability {
  AVAILABILITY_UNSPECIFIED = 0;
  IN_STOCK = 1;
  LOW = 2;
  SOLD_OUT = 3;
}

message StockLevel {
  reserved 2;
  reserved "title";
  string isbn = 1;
  int32 copies = 3;
  Availability availability = 4;
  string location = 5;
}
```

`title` is gone, and two `reserved` lines stand where it was: the number 2 and the name `title` may
not be used again in this message. `location` takes 5, a number nobody has ever used.

## An old client reads a new message

The new server writes a level with `next/stock.proto`; an old client reads it with the first one:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016" copies: 12 availability: IN_STOCK location: "A3"' | protoc -I next --encode=shelf.stock.v1.StockLevel next/stock.proto > new.bin
ana@api:~/shelf$ protoc --decode=shelf.stock.v1.StockLevel stock.proto < new.bin
isbn: "9786500000016"
copies: 12
availability: IN_STOCK
5: "A3"
```

Nothing failed. **The old client has no `title`**, so its code sees an empty string, which is the
price of removing a field: compatible on the wire, and still a change somebody's screen may show.
**And it kept field 5 without knowing its name.** The raw decode shows what the bytes held:

```
ana@api:~/shelf$ protoc --decode_raw < new.bin
1: "9786500000016"
3: 12
4: 1
5: "A3"
```

An unknown field is not thrown away. Old code that reads a message, changes one field and writes it
on keeps the fields it did not understand, which matters when a message passes through a service
that was built before the field existed. Here old Python code takes a copy off the count and writes
the message out again:

```
ana@api:~/shelf$ python3 -c 'import sys, stock_pb2; m = stock_pb2.StockLevel.FromString(sys.stdin.buffer.read()); m.copies -= 1; sys.stdout.buffer.write(m.SerializeToString())' < new.bin | protoc --decode_raw
1: "9786500000016"
3: 11
4: 1
5: "A3"
```

`copies` went from 12 to 11, and `5: "A3"` is still there.

## Why a number is never reused

Suppose somebody later wants a `location` with a smaller number and picks 2, because it is free. Every
client still on the first `stock.proto` would read the location as the **title**, because the bytes for a
string in field 2 are exactly what it expects, so it would print `A3` where a book's name should be,
and nothing anywhere would report an error. `reserved` is what stops it, and `protoc` refuses the
file:

```
ana@api:~/shelf$ sed 's/location = 5/location = 2/' next/stock.proto > reuse.proto
ana@api:~/shelf$ protoc reuse.proto -o /dev/null
reuse.proto: Field "location" uses reserved number 2.
reuse.proto: Suggested field numbers for shelf.stock.v1.StockLevel: 5
```

## What is safe

| change | an old reader | verdict |
|---|---|---|
| add a field with a new number | skips it, or keeps it as unknown | safe |
| remove a field and reserve its number | sees the zero value | safe on the wire; check who read it |
| rename a field, same number | sees no difference | safe on the wire; breaks code that uses the name, and JSON |
| change a field's type | misreads the bytes, or fails | breaking |
| reuse a number | reads the new field as the old one | breaking, and silent |
| change a method's name or its messages | gets `UNIMPLEMENTED` or garbage | breaking |

A change in the last three rows is a new package, `shelf.stock.v2`, served beside `v1` until the last
client moves, which is lesson 1's versioning rule applied to a contract file.
