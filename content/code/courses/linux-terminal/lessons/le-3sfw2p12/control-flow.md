---
title: `if`, `foreach`, `switch` — and `Set-StrictMode`
version: 1
---

The shapes are C-like and there is very little to learn.

```
PS /home/ana/work/ps> $hosts = "web01","web02","db01"
PS /home/ana/work/ps> if ($hosts.Count -gt 2) { "more than two" } else { "two or fewer" }
more than two
```

**The condition is in parentheses and the block is in braces**, both required.
There is no `then`, no `fi`, and no `;` before the brace — the brace is the
grammar. `elseif` is one word.

Unlike bash (section 144), **the condition is an expression, not a command**.
`if (Get-Process pwsh) { }` works because a non-empty result is truthy, but the
normal thing is a comparison.

```
PS /home/ana/work/ps> if ("false") { "truthy" } else { "falsy" }
truthy
PS /home/ana/work/ps> if (0) { "truthy" } else { "falsy" }
falsy
PS /home/ana/work/ps> if (@()) { "truthy" } else { "falsy" }
falsy
PS /home/ana/work/ps> if ("") { "truthy" } else { "falsy" }
falsy
```

Truthy: a non-zero number, a non-empty string, a non-empty collection, a non-null
object. Falsy: `0`, `""`, `$null`, `@()`, `$false`.

**And the string `"false"` is truthy**, because it is a non-empty string. That is
how a setting read out of a configuration file does the exact opposite of what it
says:

```
PS /home/ana/work/ps> [bool]"false"
True
PS /home/ana/work/ps> [System.Convert]::ToBoolean("false")
False
```

The cast you reach for is the wrong one. `[System.Convert]::ToBoolean` reads the
word; `[bool]` asks whether there is anything there.

## Loops

```
PS /home/ana/work/ps> foreach ($h in "web01","db01") { "checking $h" }
checking web01
checking db01
PS /home/ana/work/ps> 1..4 | ForEach-Object { $_ * $_ }
1
4
9
16
PS /home/ana/work/ps> $i = 0; while ($i -lt 3) { "i=$i"; $i++ }
i=0
i=1
i=2
```

**`foreach` and `ForEach-Object` are different things** with confusingly similar
names.

| | |
|---|---|
| `foreach ($x in $coll) { }` | a keyword. The collection must be in memory already |
| `$coll \| ForEach-Object { }` | a cmdlet. Streams, one object at a time, `$_` is the item |

`foreach` is faster; `ForEach-Object` streams, so it is what you want when the
collection is a million lines or is arriving over a network. The alias for
`ForEach-Object` is `%`, and `foreach` is *also* an alias for `ForEach-Object`
when it appears after a pipe — which is a genuine wart and the reason to write
the cmdlet name out.

`for`, `do…while` and `do…until` exist and look the way you expect.

`break` and `continue` work in loops:

```
PS /home/ana/work/ps> foreach ($n in 1,2,3) { if ($n -eq 2) { continue }; "n=$n" }
n=1
n=3
```

**They do not behave the same inside a `ForEach-Object` block**, because that is
a function called once per object rather than a loop. Filter with `Where-Object`
first, or use the `foreach` keyword, and the question does not arise.

## `switch`

```
PS /home/ana/work/ps> switch ("report.log") { {$_ -like "*.log"} { "a log file" } {$_ -like "*.csv"} { "a spreadsheet" } default { "no idea" } }
a log file
```

`switch` takes a value and a list of `condition { action }` pairs. A condition
can be a literal, a wildcard (with `-Wildcard`), a regular expression (with
`-Regex`), or a block that returns a boolean, as above.

And here is the difference from `case` in section 146, which will catch you once:

```
PS /home/ana/work/ps> switch (3) { 1 { "one" } 3 { "three" } 3 { "three again" } default { "other" } }
three
three again
```

**Every matching branch runs.** `case` stops at the first match and `switch` does
not — it keeps going through the list. `break` inside a branch stops it, which is
why real PowerShell `switch` blocks are full of `break` and bash `case` blocks
have none.

`default` runs only when nothing matched.

`switch` also takes a collection and runs the whole thing per element, which is a
neat way to classify a list:

```
PS /home/ana/work/ps> switch -Regex ("ERROR: disk full","WARN: slow","ERROR: again") { "^ERROR" { "err: $_" } "^WARN" { "warn: $_" } }
err: ERROR: disk full
warn: WARN: slow
err: ERROR: again
```

Three strings in, one `switch`, `$_` holding each in turn. That is a whole
log-classifying loop with no loop in it.

## `Set-StrictMode`

Bash's `set -u` has an exact counterpart, and it is off by default the same way.

```
PS /home/ana/work/ps> if ($nothing.Count -gt 2) { "more than two" } else { "two or fewer" }
two or fewer
PS /home/ana/work/ps> Set-StrictMode -Version Latest
PS /home/ana/work/ps> if ($nothing.Count -gt 2) { "more than two" } else { "two or fewer" }
InvalidOperation: The variable '$nothing' cannot be retrieved because it has not been set.
```

**Without it, a typo'd variable name is `$null`, `$null.Count` is 0, and the
`else` branch runs.** That is section 143's `$TARGE` in a different language:
no error, a decision taken on a value that was never there.

| | |
|---|---|
| `Set-StrictMode -Version Latest` | uninitialised variables, bad property names, bad method calls |
| `$ErrorActionPreference = 'Stop'` | the `set -e` half. The next section |

**Both lines belong at the top of every script you write**, for the same reason
`set -euo pipefail` does, and with the same caveat: they are not a safety net,
they are two classes of silent wrong answer turned into a stop.
