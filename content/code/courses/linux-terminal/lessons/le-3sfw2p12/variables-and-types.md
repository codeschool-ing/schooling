---
title: Variables have types, and the left operand decides
version: 1
---

```
PS /home/ana/work/ps> $name = "ana"; $name.GetType().Name
String
PS /home/ana/work/ps> $n = 42; $n.GetType().Name
Int32
```

A variable is `$name`, with the `$` on both sides of the assignment — unlike
bash, where it is absent on the left. Spaces around the `=` are fine.

**And the value has a type.** `42` is an `Int32`, not the two characters `42`,
which is the thing bash does not have and the reason everything in this lesson
works.

## Conversion happens, and the direction matters

```
PS /home/ana/work/ps> $n = "42"; $n + 1
421
PS /home/ana/work/ps> $n = 42; $n + "1"
43
PS /home/ana/work/ps> [int]"42" + 1
43
```

Same two values, opposite answers.

**The left operand decides.** String plus number is concatenation; number plus
string converts the string and adds. This is the same rule as the comparison trap
in the filtering section, and it is worth stating once as a rule because it
explains both:

> PowerShell converts the **right** operand to the type of the **left** one.

`[int]`, `[double]`, `[datetime]`, `[string]`, `[bool]` in square brackets in
front of a value is a cast, and it is how you stop guessing.

A cast can also go on the variable, and then it sticks:

```
PS /home/ana/work/ps> [int]$count = 0; $count = "twelve"
MetadataError: Cannot convert value "twelve" to type "System.Int32". Error: "The input string 'twelve' was not in a correct format."
```

**An error, rather than a silent change of type.** A variable declared with a
type keeps it, which is the closest thing PowerShell has to `readonly` and is
more useful.

## Strings

```
PS /home/ana/work/ps> $x = 5; "the answer is $x, and twice it is $(2*$x)"
the answer is 5, and twice it is 10
PS /home/ana/work/ps> 'no expansion here: $x'
no expansion here: $x
```

**Double quotes expand, single quotes do not** — the same division as section
141, with the same consequence for regular expressions and anything containing a
`$`.

**`$( )` inside a double-quoted string** runs an expression, which is how you get
a property into a message:

```
PS /home/ana/work/ps> "$f.Name"
/home/ana/work/ps/sales.csv.Name
PS /home/ana/work/ps> "$($f.Name) is $($f.Length) bytes"
sales.csv is 788 bytes
```

Without the `$( )`, the variable expanded on its own and `.Name` was four
literal characters after it — a small daily annoyance until you learn it.

The escape character is a **backtick**, not a backslash:

```
PS /home/ana/work/ps> "a`tb`nc"
a       b
c
PS /home/ana/work/ps> "C:\Users\ana"
C:\Users\ana
```

`` `n `` is a newline, `` `t `` a tab, `` `$ `` a literal dollar. **Backslash is
an ordinary character**, which is why Windows paths can be written without
doubling them, and why a regular expression in a double-quoted string is a
minefield — `"\d+"` is fine, but use single quotes and stop thinking about it.

Here-strings are the multi-line form:

```sh
@"
expands $variables
"@

@'
does not expand anything
'@
```

## Objects, not strings that look like things

```
PS /home/ana/work/ps> $d = Get-Date; $d.GetType().FullName; $d.AddDays(7).DayOfWeek
System.DateTime
Tuesday
```

`Get-Date` does not return text. It returns a `DateTime`, which knows what a week
is. The bash equivalent is `date -d '+7 days' +%A`, which is `date` doing the
arithmetic because the shell cannot.

And strings have methods, because a string is an object too:

```
PS /home/ana/work/ps> "hello".ToUpper(); "  padded  ".Trim(); "a,b,c".Split(",")
HELLO
padded
a
b
c
```

`.ToUpper()`, `.Trim()`, `.Split()`, `.Replace()`, `.StartsWith()`,
`.PadLeft()` — the whole .NET string library, on any string. That is `tr`, `sed`
and `cut` from lesson 8, as methods, without a process each.

**Note the parentheses.** `.Trim()` is a method and needs them; `.Length` is a
property and must not have them. Getting it wrong is not an error:

```
PS /home/ana/work/ps> "hello".Length
5
PS /home/ana/work/ps> "hello".Trim
OverloadDefinitions
-------------------
string Trim()
string Trim(char trimChar)
string Trim(Params char[] trimChars)
```

A method without its parentheses prints **the method's signatures**, which is
occasionally exactly what you wanted — it is how you find out that `Trim` takes
an optional character — and is otherwise a sign you left the brackets off.

## Special variables

| | |
|---|---|
| `$_` | the current pipeline object |
| `$?` | did the last thing succeed. A boolean, not a number |
| `$LASTEXITCODE` | the exit status of the last **native** program |
| `$null` | nothing. `$null -eq $x` is the safe order to write |
| `$true` `$false` | booleans, spelled out |
| `$PSVersionTable` | what you are running |
| `$IsLinux` `$IsWindows` `$IsMacOS` | which platform |
| `$env:NAME` | an environment variable |

`$env:PATH` is how you read the environment, and setting it with
`$env:LEVEL = "debug"` exports it to children — the `export` of section 140,
built into the name.

`$IsLinux` and friends are how a cross-platform script branches:

```
PS /home/ana/work/ps> $PSVersionTable.Platform; $IsLinux; $IsWindows; $IsMacOS
Unix
True
False
False
```

That is this machine answering. On the Windows box these scripts are meant for,
the second and third swap over — and that is one of the few things in this lesson
you will have to take on trust, because there is no Windows here to run it on.
