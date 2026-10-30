---
title: A compiler that will not convert for you
version: 1
---

Many languages turn an integer into a decimal when you add the two, and say nothing. **Swift never
converts one number type into another unless you write the conversion.** It is the first place the
compiler's strictness shows up in an ordinary sum, and it is deliberate:

```swift
// Mix.swift
let minutes = 45
let hours = 1.5
let total = minutes + hours
print(total)
```

```
ana@vm:~/sw/l01$ swiftc Mix.swift -o mix
Mix.swift:4:21: error: binary operator '+' cannot be applied to operands of type 'Int' and 'Double'
2 | let minutes = 45
3 | let hours = 1.5
4 | let total = minutes + hours
  |                     |- error: binary operator '+' cannot be applied to operands of type 'Int' and 'Double'
  |                     `- note: overloads for '+' exist with these partially matching parameter lists: (Double, Double), (Int, Int)
5 | print(total)
6 | 
```

The error says that `+` has no version taking an `Int` and a `Double`, and the note lists the two it
does have: two `Double`s, or two `Int`s. **You choose which one you meant**, and the choice matters,
because the two answers differ:

```swift
// MixFixed.swift
let minutes = 45
let hours = 1.5
let asHours = Double(minutes) / 60 + hours
let asMinutes = minutes + Int(hours * 60)
print(asHours, asMinutes)
```

```
ana@vm:~/sw/l01$ swift MixFixed.swift
2.25 135
```

`Double(minutes)` and `Int(hours * 60)` are **conversions**, written where they happen. A reader can
see each place a value changes type and what was rounded along the way. Section 06 showed that a
literal such as `60` adapts to the other side, so `Double(minutes) / 60` needs no second conversion.

## An overflow stops the program

An `Int8` holds −128 to 127. Add one to 127 and many languages wrap round to −128 without a word.
Swift checks every arithmetic operation on integers and **stops the program** instead:

```swift
// Over.swift
let small: Int8 = 127
let more = small + 1
print(more)
```

```
ana@vm:~/sw/l01$ swiftc Over.swift -o over
ana@vm:~/sw/l01$ ./over 2>&1 | head -4

*** Signal 4: Backtracing from 0x562f02b17ed3... done ***

*** Program crashed: Illegal instruction at 0x0000562f02b17ed3 ***
```

The compiler accepted it, because `small` is a name and not a literal, and the overflow happens
while the program runs. The program then crashed before `print`, with "Illegal instruction": the
check found an overflow and executed an instruction whose only purpose is to stop the process. The
full report runs to some fifty lines of addresses and registers, and `head -4` keeps the first
four; the line that names the crash is the fourth.

**A crash is the safe outcome here.** A total that silently became −128 would be stored, synced and
shown to a student as their week. When you really want wrapping arithmetic, for a checksum, Swift
has separate operators for it, `&+` and `&-`, so the intention is written down.

## Text into a number may fail

A number typed by a student arrives as text. `Int("45")` converts it, and the conversion can fail,
because `"forty-five"` is not a number:

```swift
// Parse.swift
let typed = "45"
let minutes = Int(typed)
print(minutes)
```

```
ana@vm:~/sw/l01$ swift Parse.swift
Parse.swift:4:7: warning: expression implicitly coerced from 'Int?' to 'Any'
2 | let typed = "45"
3 | let minutes = Int(typed)
4 | print(minutes)
  |       |- warning: expression implicitly coerced from 'Int?' to 'Any'
  |       |- note: provide a default value to avoid this warning
  |       |- note: force-unwrap the value to avoid this warning
  |       `- note: explicitly cast to 'Any' with 'as Any' to silence this warning
5 | 
Optional(45)
```

The program ran and printed `Optional(45)`, not `45`, after a warning about the same line. `Int(typed)`
does not return an `Int`. It returns an `Int?`, an **optional**: either a number or nothing at all,
and the warning is the compiler pointing out that you printed the wrapper rather than the number.
Lesson 2 is about this type: what the `?` means, the four ways to get the number out, and the one
way that crashes.
