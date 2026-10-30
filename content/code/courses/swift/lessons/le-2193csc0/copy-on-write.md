---
title: Copies that are not made until somebody writes
version: 1
---

Section 03 promised that copying a struct is cheap even when the struct holds an array of a thousand
sessions. **The copy is real in what you can observe and deferred in what the machine does.** An
array keeps its elements in a buffer of memory elsewhere, and an assignment copies only the small
struct that refers to the buffer. Both arrays then share one buffer until one of them is changed,
and that change is the moment the elements are copied. It is called **copy-on-write**, and it can be
watched by asking each array where its buffer is:

```swift
// Cow.swift
func buffer(_ array: [Int]) -> UnsafeRawPointer {
    array.withUnsafeBufferPointer { UnsafeRawPointer($0.baseAddress!) }
}
let week = [45, 30, 60]
var copy = week
print("after the assignment, same buffer:", buffer(week) == buffer(copy))
copy.append(90)
print("after the append, same buffer:", buffer(week) == buffer(copy))
print(week, copy)
```

```
ana@vm:~/sw/l05$ swift Cow.swift
after the assignment, same buffer: true
after the append, same buffer: false
[45, 30, 60] [45, 30, 60, 90]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l05-cow\" aria-label=\"Two stages. First, after var copy = week, the arrays week and copy both point to one buffer holding 45, 30, 60. Second, after copy.append(90), week still points to the old buffer and copy points to a new one holding 45, 30, 60, 90.\"><defs><marker id=\"l05-cow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l05-cow-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">after var copy = week</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">after copy.append(90)</text><path d=\"M355 10 L355 210\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">week</text><path d=\"M110 65 L198 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"30\" y=\"110\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copy</text><path d=\"M110 125 L198 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"200\" y=\"78\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60]</text><text x=\"170\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one buffer, two arrays</text><rect x=\"390\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">week</text><path d=\"M470 65 L528 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"530\" y=\"48\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60]</text><rect x=\"390\" y=\"110\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copy</text><path d=\"M470 125 L528 125\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah2)\"></path><rect x=\"530\" y=\"108\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60, 90]</text><text x=\"540\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the write copied it first</text></svg>", "caption": "An assignment shares the buffer; the first write to a shared buffer copies it, and only the array that wrote gets the new one."}
```

`withUnsafeBufferPointer` lends you the address of an array's elements for the length of a closure,
and the word `Unsafe` in its name is a warning worth heeding: nothing in this course needs it apart
from this measurement. The answer is what matters. **One buffer after the assignment, two after the
append**, and the original kept its three elements. Arrays, dictionaries, sets and strings all work
this way, so passing a large one to a function costs nothing until somebody writes to it.

## Your own struct gets it for free, mostly

A struct whose properties are arrays and strings inherits their behaviour: copying it copies a few
references to buffers, and the buffers are copied when written. A struct of your own that holds a
**class** instance does not, because the class is shared and nothing copies it. The standard library
gives you the tool to build copy-on-write yourself, `isKnownUniquelyReferenced`, which answers
whether a class instance has exactly one reference to it:

```swift
// Unique.swift
final class Storage {
    var minutes: [Int] = []
}
struct Log {
    var storage = Storage()
    mutating func add(_ session: Int) {
        if !isKnownUniquelyReferenced(&storage) {
            print("shared, copying before writing")
            let fresh = Storage()
            fresh.minutes = storage.minutes
            storage = fresh
        }
        storage.minutes.append(session)
    }
}
var monday = Log()
monday.add(45)
var tuesday = monday
tuesday.add(30)
print(monday.storage.minutes, tuesday.storage.minutes)
```

```
ana@vm:~/sw/l05$ swift Unique.swift
shared, copying before writing
[45] [45, 30]
```

The first `add` found the storage unshared and wrote in place. After `tuesday = monday`, two `Log`
values held one `Storage`, so the second `add` copied it first, and `monday` kept its single session.
**Without the check, `tuesday.add(30)` would have changed `monday` too**: a struct with a class inside
behaves like a class unless somebody wrote this. You will seldom write it, because arrays already do;
it is worth recognising when a type in a library documents itself as copy-on-write.
