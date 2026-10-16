---
title: Protocol Buffers
version: 1
---

**A `.proto` file describes messages: records with typed fields, each field with a name and a
number.** The name is for the people and the code that read the file. The number is for the wire,
and it is the only one of the two that ever leaves the program. That one fact explains almost every
rule in this section and the section on changing the schema.

The common wrong picture comes from JSON, where every message carries its own keys:
`{"copies": 12}` says `copies` every time it is sent. A Protocol Buffers message says `3`, and a
reader that does not have the `.proto` cannot tell you what field 3 is. The next section shows the
bytes.

This is the warehouse's contract. Save it in `~/shelf` as `stock.proto`, the same way you saved
`db.py` in lesson 1:

```
// shelf/stock.proto
// The bookshop's warehouse, as a gRPC service.
syntax = "proto3";

package shelf.stock.v1;

service Stock {
  // How many copies of one book are on the shelf.
  rpc GetStock(BookRef) returns (StockLevel);
  // Take copies off the shelf for an order, if there are enough.
  rpc Reserve(ReserveRequest) returns (Reservation);
  // The level now, then again every time it changes.
  rpc WatchStock(BookRef) returns (stream StockLevel);
  // A delivery, one box at a time, and one summary at the end.
  rpc Restock(stream Delivery) returns (RestockSummary);
}

enum Availability {
  AVAILABILITY_UNSPECIFIED = 0;
  IN_STOCK = 1;
  LOW = 2;
  SOLD_OUT = 3;
}

message BookRef {
  string isbn = 1;
}

message StockLevel {
  string isbn = 1;
  string title = 2;
  int32 copies = 3;
  Availability availability = 4;
}

message ReserveRequest {
  string isbn = 1;
  int32 copies = 2;
}

message Reservation {
  string isbn = 1;
  int32 copies = 2;
  int32 left = 3;
}

message Delivery {
  string isbn = 1;
  int32 copies = 2;
}

message RestockSummary {
  int32 boxes = 1;
  int32 copies = 2;
  repeated string isbns = 3;
}
```

The `service` block at the top is the section after next. Everything below it is the data.

## Messages and field numbers

`StockLevel` has four fields. `string isbn = 1;` reads as: a field called `isbn`, of type `string`,
sent on the wire as **field number 1**. The numbers only have to be unique inside one message, so
`BookRef`, `StockLevel` and `ReserveRequest` all have an `isbn` that is field 1, and nothing
connects them.

Numbers 1 to 15 fit in a one-byte tag and 16 to 2047 need two, so the fields that travel in every
message get the small ones. **A number, once used, belongs to that field forever.**
The section on changing the schema shows what happens when somebody forgets.

## Scalar types

| type | holds | note |
|---|---|---|
| `string` | text | always UTF-8 |
| `bytes` | any bytes | an image, a hash, another format |
| `bool` | true or false | |
| `int32`, `int64` | whole numbers | a negative one costs ten bytes on the wire |
| `sint32`, `sint64` | whole numbers | for fields that are often negative |
| `double`, `float` | floating point | never for money; lesson 1's cents rule holds here too |

`copies` is an `int32` because a shelf holds far fewer than two thousand million books and never a
negative number of them.

## `repeated`, and enums

**`repeated` makes a field a list.** `RestockSummary` carries one `isbns` field holding every book a
delivery touched, in the order they first arrived. In Python it behaves like a list, in Go it is a slice.

**An enum is a named set of numbers, and its first value must be zero.** That is a rule of the
language, and the reason is the next point: zero is what a reader sees when the field was never set.
So the zero value of `Availability` is `AVAILABILITY_UNSPECIFIED`, a name that means "nobody said",
and not `IN_STOCK`, which would make a missing value look like good news.

## A field that is not sent is zero

In this version of the language, `proto3`, a field set to its zero value is not sent at all, and a
reader that finds it missing returns the zero value: `0`, the empty string, `false`, or the enum's
first value. **A reader cannot tell "zero copies" from "nobody told me the copies".** For `copies`
that is fine, because the server always fills it in. Where the difference matters, the field is
declared `optional int32 copies = 3;`, and the generated code gains a way to ask whether it was set.

The package, `shelf.stock.v1`, is the version from lesson 1 moved into the contract. A change that
cannot be made compatibly goes into `shelf.stock.v2`, beside it, and the section on changing the
schema is about avoiding that.
