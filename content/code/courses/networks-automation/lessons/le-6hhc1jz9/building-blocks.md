---
title: Containers, lists and leaves
version: 1
---

Four kinds of node build almost every model:

- A **container** groups nodes and holds no value itself: `interfaces`.
- A **list** holds entries, each identified by its **key**: `interface`, keyed by `name`. Two
  entries with the same key cannot exist, which is what made the lab's API answer `409` in lesson
  2 and what lets a RESTCONF URL write `interface=eth1`.
- A **leaf** holds one value of one type: `description`.
- A **leaf-list** holds several values of one type, with no key of their own: a list of DNS
  servers, for instance.

A leaf's type can carry restrictions, and those are the rules a device enforces. Here is the
leaf lesson 3 broke with a prefix length of 33, in the source of `ietf-ip`:

```
ana@ctl:~$ grep -n -B2 -A10 "leaf prefix-length {" ietf/ietf-ip.yang | head -13
212-             if the server supports non-contiguous netmasks, as
213-             a netmask.";
214:          leaf prefix-length {
215-            type uint8 {
216-              range "0..32";
217-            }
218-            description
219-              "The length of the subnet prefix.";
220-          }
221-          leaf netmask {
222-            if-feature ipv4-non-contiguous-netmasks;
223-            type yang:dotted-quad;
224-            description
```

`uint8` is an unsigned 8-bit integer, 0 to 255, and **`range "0..32"` narrows it to the values
an IPv4 prefix length can have**. Nothing else in the model or the device had to be written for
`nc1` to refuse 33: Clixon read that line, and the error message it printed in lesson 3 quoted the
range and the file.

The other restrictions a type can carry follow the same idea:

| restriction | on | example |
|---|---|---|
| `range` | numbers | `range "1..999"` |
| `length` | strings | `length "1..32"` |
| `pattern` | strings, as a regular expression | what `inet:ipv4-prefix` is made of |
| `enumeration` | a fixed set of words | `enum planned; enum active;` |

Two structures sit around the nodes. A **choice** says that exactly one of several alternatives
may be present: `ietf-ip`'s `subnet` is either `prefix-length` or `netmask`, never both. A
**typedef** names a restricted type so it can be reused; `inet:ipv4-address` is one, defined once
in `ietf-inet-types` and used across the IETF's other modules.
