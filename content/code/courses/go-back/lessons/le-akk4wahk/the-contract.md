---
title: The contract, in a .proto file
version: 1
---

The service is written down before any Go exists, in `~/boxoffice/proto/seats.proto`:

```
// boxoffice/proto/seats.proto
syntax = "proto3";

package boxoffice.v1;

option go_package = "example.com/boxoffice/internal/seatspb";

// Seats is boxoffice's service for the other programs of the venue.
service Seats {
  // GetEvent answers one event.
  rpc GetEvent(GetEventRequest) returns (Event);
  // Watch sends an event's availability now, and again whenever it changes.
  rpc Watch(WatchRequest) returns (stream Availability);
  // Scan reads the tickets presented at the door and answers once, at the end.
  rpc Scan(stream ScanRequest) returns (ScanSummary);
}

message GetEventRequest {
  int32 id = 1;
}

message Event {
  int32 id = 1;
  string name = 2;
  int32 seats = 3;
  int32 sold = 4;
}

message WatchRequest {
  int32 event_id = 1;
}

message Availability {
  int32 event_id = 1;
  int32 available = 2;
}

message ScanRequest {
  int32 ticket_id = 1;
}

message ScanSummary {
  int32 admitted = 1;
  int32 refused = 2;
}
```

Read it in three layers:

- **The header.** `syntax = "proto3"` is the current version of the language. `package boxoffice.v1`
  names the contract, and the `v1` is there on purpose: a contract that one day must break is published
  as `v2` beside it, rather than changed under its clients. `go_package` says which Go package the
  generated code belongs to, here `internal/seatspb` in boxoffice's module.
- **The service.** Three `rpc` lines, one per function, each with its request type and its response
  type. **The word `stream` decides the kind of call**: on the response side for `Watch`, on the request
  side for `Scan`. The comments above them travel into the generated Go.
- **The messages.** Each field has a type, a name, and **a number. The number is what travels**, not the
  name; it is the field's identity for ever, and section 09 is about what that means when the contract
  changes.

`.proto` has no syntax highlighting in this course's code blocks, and it needs little: it reads like a
very small Go.

## What the numbers buy

`protoc` can encode a message from a readable text form and decode it again, which shows exactly what
crosses the network. Here is the jazz event as bytes, how many there are, and what a reader sees
**without** the `.proto`:

```
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | od -An -tx1
 08 01 12 11 4a 61 7a 7a 20 61 74 20 74 68 65 20
 44 6f 63 6b 73 18 78 20 02
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | wc -c
25
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | protoc --decode_raw
1: 1
2: "Jazz at the Docks"
3: 120
4: 2
ana@vm:~/boxoffice$ printf '%s' '{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2}' | wc -c
56
```

**25 bytes against the 56 of the same event as JSON.** Read the first bytes: `08 01` is field 1 holding
the number 1; `12 11` is field 2, a string of 17 (`0x11`) bytes, followed by the letters of *Jazz at the
Docks*; `18 78` is field 3, 120; `20 02` is field 4, 2. The names `id`, `name`, `seats` and `sold`
appear nowhere: **`--decode_raw` can recover the numbers and the values, and only the contract can say
what they mean.** That is the trade, and lesson 11 measures it on a larger answer.
