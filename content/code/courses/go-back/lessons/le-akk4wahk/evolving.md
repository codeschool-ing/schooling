---
title: Changing a contract without breaking its callers
version: 1
---

The contract will change. The door scanners were built against today's `seats.proto`, and next month the
box office wants events to carry their venue. **Clients and servers are deployed at different times**, so
for a while an old scanner talks to a new server, or a new scanner to an old one. Protocol Buffers was
designed for exactly that, and the design rests on the field numbers of section 04.

## Adding a field

A new version of the contract adds `venue` as field 5. To see what an old reader makes of it, encode an
event with the new contract and decode it with the old one:

```
ana@vm:~/boxoffice$ sed 's/  int32 sold = 4;/  int32 sold = 4;\n  string venue = 5;/' proto/seats.proto > /tmp/seats_v2.proto && grep -A6 '^message Event' /tmp/seats_v2.proto
message Event {
  int32 id = 1;
  string name = 2;
  int32 seats = 3;
  int32 sold = 4;
  string venue = 5;
}
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2 venue: "Main Hall"' | protoc -I/tmp --encode=boxoffice.v1.Event /tmp/seats_v2.proto | protoc --decode=boxoffice.v1.Event proto/seats.proto
id: 1
name: "Jazz at the Docks"
seats: 120
sold: 2
5: "Main Hall"
```

**The old contract read every field it knew and kept the one it did not as `5: "Main Hall"`**, a field
number and a value. Nothing failed. In Go, such a field lands in the message's `unknownFields`, section
05's bookkeeping, and is even sent on if the message is passed along. The other direction works too: a
new reader that receives an old message, with no field 5, finds `venue` at its zero value, `""`. **That is
why adding a field is always safe**, and why a reader must treat a zero as possibly "not sent".

## The rules that keep it safe

| change | safe | why |
|---|---|---|
| add a field with a new number | yes | old readers keep it as unknown; new readers see zero in old messages |
| rename a field, same number | yes, on the wire | only the number travels; the generated Go names change, so code that uses them must change too |
| remove a field | yes, if its number is reserved | `reserved 5;` stops anybody reusing the number for something else |
| change a field's number | **no** | to every existing reader it is a different field |
| reuse a removed field's number | **no** | old messages in queues and logs would be read as the new meaning |
| change a field's type | mostly no | some pairs share an encoding, most do not, and the result is garbage rather than an error |
| rename or remove an `rpc` | **no** | old clients call a method that no longer exists and get `Unimplemented` |

**The numbers are the contract; the names are documentation.** A field removed from a message should leave
behind `reserved` with its number and its old name, so that nobody, in a year, gives that number a new
meaning that old messages would be decoded into.

## When the change cannot be compatible

Some changes cannot be made safely: a field that must change type, a call whose meaning changes. That is
what the `v1` in `package boxoffice.v1` is for. **A breaking change becomes `boxoffice.v2`, a new service
beside the old one**, and the server answers both until the last old client is gone. The path of every
call includes the package, `/boxoffice.v1.Seats/GetEvent` in the log of section 08, so the two versions
never collide.
