---
title: x
version: 1
---

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
