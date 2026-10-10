---
title: x
version: 1
---

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
