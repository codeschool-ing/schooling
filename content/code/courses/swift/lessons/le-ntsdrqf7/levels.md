---
title: Six levels, one question
version: 1
---

Every declaration in Swift answers one question, whether you write the answer or not: **from where
may this be used?** The answer is an access level, and there are six. Each is a region of code, and
each region contains the one below it:

| level | usable from |
|---|---|
| `private` | the enclosing declaration, and its extensions in the same file |
| `fileprivate` | anywhere in the same file |
| `internal` | anywhere in the same module. **The default**, when you write nothing |
| `package` | any module of the same package |
| `public` | any module that imports this one |
| `open` | the same as `public`, and a class or method may also be subclassed or overridden there |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l17-levels\" aria-label=\"Five nested boxes, each inside the one before. Outermost: public and open, any module that imports this one. Inside it: package, every module of this package. Inside that: internal, this module, the default. Inside that: fileprivate, this file. Innermost: private, this declaration and its extensions in this file, holding var log.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">public / open</text><text x=\"146.8\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">any module that imports this one</text><rect x=\"50\" y=\"54\" width=\"620\" height=\"238\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">package</text><text x=\"131.2\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every module of this package</text><rect x=\"80\" y=\"88\" width=\"560\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"94\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">internal</text><text x=\"168.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this module (the default)</text><rect x=\"110\" y=\"122\" width=\"500\" height=\"134\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"124\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">fileprivate</text><text x=\"221.6\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this file</text><rect x=\"140\" y=\"156\" width=\"440\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"154\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">private</text><text x=\"221.2\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this type, and its extensions in this file</text><text x=\"360\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">var log</text></svg>", "caption": "Six access levels as five regions, each inside the next. A name can be used anywhere inside the region its level names, and nowhere outside it."}
```

The common mistake is to read `private` as "hidden from other people". **Access control is about
code, not people**: it says which other code is allowed to depend on a name, so that the name can
change later without breaking that code. A `private` property is one you promise nobody outside its
type relies on, and the compiler keeps the promise for you.

## private and fileprivate, in two files

A program compiled from two files is enough to see the first two levels. `Week.swift` keeps a log
of notes as `private` and the minutes as `fileprivate`, and adds a free function in the same file
that reads the minutes:

```swift
// Week.swift
struct Week {
    private var log: [String] = []
    fileprivate var minutes: [Int] = []

    mutating func add(_ minutes: Int, note: String) {
        self.minutes.append(minutes)
        log.append(note)
    }
}

extension Week {
    var lastNote: String? { log.last }
}

func total(of week: Week) -> Int {
    week.minutes.reduce(0, +)
}
```

`main.swift` uses the week, and then reaches for both stored properties directly:

```swift
// main.swift
var week = Week()
week.add(45, note: "optionals")
week.add(30, note: "closures")
print(total(of: week), week.lastNote ?? "none")
print(week.minutes)
print(week.log)
```

When more than one file makes up a program, the top-level statements go in the file called
`main.swift`, and `swiftc` takes every file on one line:

```
ana@vm:~/sw/l17/levels$ swiftc Week.swift main.swift -o week
main.swift:6:12: error: 'minutes' is inaccessible due to 'fileprivate' protection level
4 | week.add(30, note: "closures")
5 | print(total(of: week), week.lastNote ?? "none")
6 | print(week.minutes)
  |            `- error: 'minutes' is inaccessible due to 'fileprivate' protection level
7 | print(week.log)
8 | 

Week.swift:4:21: note: 'minutes' declared here
 2 | struct Week {
 3 |     private var log: [String] = []
 4 |     fileprivate var minutes: [Int] = []
   |                     `- note: 'minutes' declared here
 5 | 
 6 |     mutating func add(_ minutes: Int, note: String) {

main.swift:7:12: error: 'log' is inaccessible due to 'private' protection level
5 | print(total(of: week), week.lastNote ?? "none")
6 | print(week.minutes)
7 | print(week.log)
  |            `- error: 'log' is inaccessible due to 'private' protection level
8 | 

Week.swift:3:17: note: 'log' declared here
 1 | // Week.swift
 2 | struct Week {
 3 |     private var log: [String] = []
   |                 `- note: 'log' declared here
 4 |     fileprivate var minutes: [Int] = []
 5 | 
```

Two errors, one per line that crossed a boundary, and each points back at the declaration with a
`note`. Inside `Week.swift` the same reads were fine: the extension read `log` because it is in the
same file as the type, and `total(of:)` read `minutes` because `fileprivate` covers the whole file.
**`main.swift` is a different file, so both doors were shut.** Remove the last two lines and the
program builds:

```swift
// main.swift
var week = Week()
week.add(45, note: "optionals")
week.add(30, note: "closures")
print(total(of: week), week.lastNote ?? "none")
```

```
ana@vm:~/sw/l17/levels$ swiftc Week.swift main.swift -o week && ./week
75 closures
```

`total(of:)` is the honest way out: the file that owns `minutes` offers a function, and every other
file asks it. If `minutes` later becomes a dictionary of days, only `Week.swift` changes.

## Which one to write

**Start private and widen when the compiler asks.** A name that is `private` today can become
`internal` tomorrow in a one-word change that breaks nothing. Narrowing goes the other way: once
another file, or another module, uses a name, making it private breaks that code, and you have to
find every use first.

`fileprivate` is the rarer of the two. It earns its place when two types in one file cooperate
closely, such as a type and the small helper that formats it, and neither should be visible to the
rest of the module. For everything inside one type and its extensions, `private` already covers it.

Nothing on this page needed a module boundary: both files were compiled into one program, one
module, so `internal` names in either were visible to the other. Section 03 builds two modules.
