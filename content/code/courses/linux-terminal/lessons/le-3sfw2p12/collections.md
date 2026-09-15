---
title: Arrays and hashtables, and the count that is not there
version: 1
---

```
PS /home/ana/work/ps> $hosts = "web01","web02","db01"; $hosts.Count; $hosts[0]; $hosts[-1]
3
web01
db01
```

**A comma makes an array.** No brackets required, though `@("web01","web02")` is
the explicit form and matters below. Indexing starts at zero, and `-1` is the
last element — which bash arrays cannot do.

```
PS /home/ana/work/ps> $hosts += "cache01"; $hosts.Count
4
PS /home/ana/work/ps> $hosts | Where-Object { $_ -like "web*" }
web01
web02
```

`+=` appends. It is also a lie: **PowerShell arrays are fixed size**, so `+=`
builds a whole new array and copies everything into it. On four elements that is
invisible; in a loop over ten thousand it is the single most common reason a
PowerShell script is slow. The fix is to let the pipeline collect:

```sh
$result = foreach ($h in $hosts) { Test-Something $h }     # collects, no copying
$result = $hosts | ForEach-Object { Test-Something $_ }    # the same
```

An array pipes one element at a time, which is why `$hosts | Where-Object` works
without anything special — a collection put into the pipeline is unrolled.

## Hashtables

```
PS /home/ana/work/ps> $h = @{ name = "web01"; port = 8080 }; $h["name"]; $h.port
web01
8080
PS /home/ana/work/ps> $h.Keys
port
name
```

`@{ }` with `key = value` pairs, separated by `;` on one line or newlines in a
file. Read a value with either `$h["name"]` or `$h.name` — the dot form is
shorter and fails on a key with a space in it.

**The order is not the insertion order.** `port` came back before `name`, the
same as bash's associative arrays in section 149. `[ordered]@{ }` keeps it:

```
PS /home/ana/work/ps> $h = [ordered]@{ name = "web01"; port = 8080 }; $h.Keys
name
port
```

You want that whenever the hashtable is going to become a table, a
`pscustomobject` or a JSON document, because the column order is the key order.

`$h.Keys`, `$h.Values`, `$h.ContainsKey('port')`, `$h.Remove('port')` — and
`$h.newkey = 1` adds one.

Hashtables are also how you build an object:

```sh
[pscustomobject]@{ ip = $f[0]; path = $f[6]; status = [int]$f[8] }
```

That cast is the whole of the one-question video's parse line. A hashtable is a
bag of names and values; a `pscustomobject` is a *thing* with properties, and it
is what the pipeline wants.

## The count that is not there

This is the trap in this section, and it is a real one.

```
PS /home/ana/work/ps> $empty = @(); $empty.Count; ($empty | Measure-Object).Count
0
0
PS /home/ana/work/ps> $one = Get-ChildItem sales.csv; $one.Count
1
PS /home/ana/work/ps> @(Get-ChildItem sales.csv).Count
1
```

Those all behave. The problem is what `Get-ChildItem` **returns** when it matches
nothing or one thing: not an array of zero or one, but `$null` or the bare
object.

In PowerShell 7 a single object has a `.Count` of 1 and `$null.Count` is 0, so
the four lines above all work. **In Windows PowerShell 5.1 — which is what is on
every Windows Server — neither does**, and `$result.Count` on a single result is
`$null`, silently, and your check for "did we get exactly one" is never true.

The fix works on both and costs three characters:

```sh
@(Get-ChildItem *.log).Count       # @( ) forces an array, of zero, one or many
($x | Measure-Object).Count        # the same, through the pipeline
```

**Write `@( )` around anything whose count you are about to test.** It is free,
it is correct on every version, and the version you are wrong about is the one
you will be asked to support.

## Two more things worth knowing

**`$array + $array` concatenates** and `$hash1 + $hash2` merges — the second
throwing if a key is in both:

```
PS /home/ana/work/ps> $a = @{x=1}; $b = @{y=2}; ($a + $b).Keys
x
y
PS /home/ana/work/ps> $c = @{x=1}; $d = @{x=2}; $c + $d
OperationStopped: Item has already been added. Key in dictionary: 'x'  Key being added: 'x'
```

**`-join` and `-split` are operators**, not cmdlets:

```
PS /home/ana/work/ps> $hosts = "web01","web02"; $hosts -join ", "
web01, web02
PS /home/ana/work/ps> "one two  three" -split "\s+"
one
two
three
```

`-split` on a regular expression is `awk`'s field splitting and `tr -s ' '` from
lesson 8 in one operator, and `-join` is `paste -sd,` from section 133.
