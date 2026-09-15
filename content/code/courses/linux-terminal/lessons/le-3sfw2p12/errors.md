---
title: Errors, and two different kinds of failure
version: 1
---

PowerShell has two error classes and they behave differently. Knowing which one
you are looking at is most of this section.

```
PS /home/ana/work/ps> Get-Content /etc/nosuchfile; "this line still ran"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
this line still ran
```

**That is a non-terminating error.** The cmdlet reported it and the script went
on, which is the default and is section 143's `noset.sh` all over again.

```
PS /home/ana/work/ps> Get-Content /etc/nosuchfile -ErrorAction Stop; "this line did not"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
```

**`-ErrorAction Stop` promotes it to a terminating error**, and the second
statement never ran.

| | |
|---|---|
| `Continue` | report it and keep going. **The default** |
| `Stop` | terminate |
| `SilentlyContinue` | do not report it, keep going |
| `Ignore` | as above, and do not even record it in `$Error` |

```
PS /home/ana/work/ps> $ErrorActionPreference
Continue
```

Setting `$ErrorActionPreference = 'Stop'` at the top of a script makes **every**
cmdlet stop on error, which is as close as PowerShell gets to `set -e`. Put it
next to `Set-StrictMode -Version Latest` from section 167, and the pair is
`set -euo pipefail`.

**`SilentlyContinue` is the one to be careful with.** It is the `2>/dev/null` of
section 121, with the same problem: it hides the error you expected and also the
one you did not.

## `try` / `catch` / `finally`

```
PS /home/ana/work/ps> try { Get-Content /etc/nosuchfile -ErrorAction Stop } catch { "caught: $($_.Exception.Message)" }
caught: Cannot find path '/etc/nosuchfile' because it does not exist.
```

Real exception handling, which bash has nothing like — section 153's `trap … ERR`
is the nearest thing and it is a different shape.

**The `-ErrorAction Stop` is not optional there:**

```
PS /home/ana/work/ps> try { Get-Content /etc/nosuchfile } catch { "caught it" }; "after the try"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
after the try
PS /home/ana/work/ps> $ErrorActionPreference = "Stop"; try { Get-Content /etc/nosuchfile } catch { "caught it" }; "after the try"
caught it
after the try
```

The first `catch` never ran. `catch` only sees **terminating** errors, so a `try`
around a cmdlet reporting a non-terminating one catches nothing, the error is
printed as usual, and the block runs on. This is the mistake behind every claim
that PowerShell's `try`/`catch` does not work.

Either `-ErrorAction Stop` on the cmdlet, or `$ErrorActionPreference = 'Stop'`
once at the top — and the second is what most scripts should do.

Inside `catch`, `$_` is an `ErrorRecord`:

```
PS /home/ana/work/ps> $Error[0].GetType().FullName
System.Management.Automation.ErrorRecord
```

| | |
|---|---|
| `$_.Exception.Message` | the text |
| `$_.Exception.GetType().Name` | what kind, for `catch [System.IO.FileNotFoundException]` |
| `$_.InvocationInfo.ScriptLineNumber` | where |
| `$_.ScriptStackTrace` | how it got there |

```
PS /home/ana/work/ps> try { 1/0 } catch { $_.Exception.GetType().Name } finally { "finally ran" }
RuntimeException
finally ran
```

`finally` runs either way, and is **the `trap … EXIT` of section 153**: the place
to delete the temporary file, close the connection, put the setting back.

`$Error` is an array of everything that has gone wrong this session, newest
first, and `$Error[0]` after something confusing is the fastest way to find out
what it actually was.

## `throw`

```
PS /home/ana/work/ps> function Check { param($P) if (-not (Test-Path $P)) { throw "cannot read $P" } ; "ok" }
PS /home/ana/work/ps> Check /etc/hostname
ok
PS /home/ana/work/ps> try { Check /etc/nope } catch { "died: $($_.Exception.Message)" }
died: cannot read /etc/nope
```

`throw` raises a terminating error with your message — the `die()` of section
150, built in, and catchable by whoever called you, which `die()` is not. It is
the right way for a function to refuse.

## `$?` and `$LASTEXITCODE` are different things

This matters the moment your script calls a native program, which on Linux is
constantly.

```
PS /home/ana/work/ps> ls /etc/nosuchfile; "$? is $?"
/usr/bin/ls: cannot access '/etc/nosuchfile': No such file or directory
False is False
PS /home/ana/work/ps> ls /etc/nosuchfile; "LASTEXITCODE is $LASTEXITCODE"
/usr/bin/ls: cannot access '/etc/nosuchfile': No such file or directory
LASTEXITCODE is 2
PS /home/ana/work/ps> Get-Content /etc/nosuchfile; "$? is $?, LASTEXITCODE is still $LASTEXITCODE"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
False is False, LASTEXITCODE is still 2
PS /home/ana/work/ps> ls /etc/hostname; "$? is $?, LASTEXITCODE is $LASTEXITCODE"
/etc/hostname
True is True, LASTEXITCODE is 0
```

| | |
|---|---|
| `$?` | a **boolean**: did the previous statement succeed. Set by everything |
| `$LASTEXITCODE` | an **integer**: the exit status of the last native program |

Read the third line again. `Get-Content` failed, `$?` went `False` — and
`$LASTEXITCODE` still said `2`, left over from the `ls` two lines earlier.
**Cmdlets do not touch `$LASTEXITCODE`**, so it is stale until the next external
program runs, and a script checking it after a cmdlet is reading an old answer.

And the other direction: **`-ErrorAction Stop` does nothing to a native
program**, because `ls` does not know what an ErrorAction is. Checking an
external command means checking `$LASTEXITCODE` yourself:

```sh
git clone $url
if ($LASTEXITCODE -ne 0) { throw "clone failed" }
```

`$?` is `False` for a failed native program too, as the first line shows, so
`if (-not $?)` works — as long as it is the very next statement, because anything
in between sets it.

## What to put at the top

```sh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

Two lines. The first catches the variable that was never set, the second stops at
the first cmdlet that fails. Neither notices a native program that returned 1,
which is the hole you have to cover by hand — the same shape of gap that
section 143 measured in `set -e`.
