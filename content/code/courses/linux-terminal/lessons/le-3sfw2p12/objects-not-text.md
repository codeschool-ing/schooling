---
title: The pipeline carries objects, and everything follows from that
version: 1
---

Every tool in lesson 8 read text and wrote text. `grep` matched characters,
`cut` counted delimiters, `awk` split on whitespace. That is the Unix idea, and
it works because every program agrees to speak the same lowest common
denominator.

**PowerShell made the other choice.** A command emits objects — things with
named, typed properties — and the next command in the pipeline receives those
objects rather than a rendering of them.

```
PS /home/ana/work/ps> Get-ChildItem | Select-Object -First 3
    Directory: /home/ana/work/ps

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-r--r--        ana ana        09/15/2026 10:48       148233 access.log
-rw-r--r--        ana ana        09/15/2026 10:48          788 sales.csv
```

That table looks like `ls -l` output. It is not. **It is a rendering, produced
at the very end, of two objects that were never text at any point.** Ask what
they are:

```
PS /home/ana/work/ps> Get-ChildItem | Get-Member -MemberType Property | Select-Object -First 8
   TypeName: System.IO.FileInfo

Name            MemberType Definition
----            ---------- ----------
Attributes      Property   System.IO.FileAttributes Attributes {get;set;}
CreationTime    Property   datetime CreationTime {get;set;}
CreationTimeUtc Property   datetime CreationTimeUtc {get;set;}
Directory       Property   System.IO.DirectoryInfo Directory {get;}
DirectoryName   Property   string DirectoryName {get;}
Exists          Property   bool Exists {get;}
Extension       Property   string Extension {get;}
FullName        Property   string FullName {get;}
```

`Get-Member` is the most useful command in PowerShell and the first one to
learn. It answers "what is this thing, and what can I ask it".

## What that buys

```
PS /home/ana/work/ps> (Get-ChildItem sales.csv).Length
788
PS /home/ana/work/ps> (Get-ChildItem sales.csv).LastWriteTime.Year
2026
```

Compare with the bash for the same two questions:

```sh
ls -l sales.csv | awk '{print $5}'      # the size — if the filename has no spaces
ls -l sales.csv | awk '{print $8}'      # the year — if the file is over six months old
```

**The `awk` version is counting columns in a rendering.** Lesson 8's own `cut`
section was about that going wrong, and its `awk` section measured it: in a
twelve-hundred-line log where every line looks the same shape, `awk '{print NF}'`
reports four different field counts, because one field is free text with spaces
in it.

`.Length` cannot have that problem. It is not the fifth word of anything; it is
a number on an object, and it is the same number whatever the name contains.

And `.LastWriteTime.Year` is the part that has no bash equivalent at all:
`LastWriteTime` is not a string that looks like a date, it is a `DateTime`, so
it has a `.Year`, an `.AddDays(7)`, and a comparison that understands months.

## What it costs

Three things, and they are real.

**It is verbose.** `Get-ChildItem | Where-Object { $_.Length -gt 1000 }` against
`ls -l | awk '$5>1000'`. Aliases help at a prompt — `gci`, `?`, `%` — and make a
script unreadable.

**It is slower to start.** PowerShell starts a .NET runtime:

```
ana@vm:~/work/ps$ time pwsh -NoProfile -Command 'Write-Output hello'
hello

real	0m0.405s
user	0m0.387s
sys	0m0.146s
ana@vm:~/work/ps$ time bash -c 'echo hello'
hello

real	0m0.003s
user	0m0.000s
sys	0m0.003s
```

A hundred and thirty times, on this machine. For a shell you type at, nobody
notices; for something a scheduler runs every minute, somebody does.

**The objects are only as good as the command that made them.** A cmdlet that
returns a typed object is a pleasure; a cmdlet that returns strings you then have
to parse gives you the worst of both. And when you read a plain text file, you
are back to parsing — which is the section on the pipeline, and the trap in the
section on filtering.

## Where this lesson stands

**This is an overview.** It is enough to read a script somebody hands you, write
a short one, and know what to search for. It is not a PowerShell course.

And it was captured on PowerShell 7 running on Linux:

```
PS /home/ana/work/ps> $PSVersionTable
Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
GitCommitId                    7.4.6
OS                             Ubuntu 24.04.4 LTS
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

The language, the pipeline, the objects and the errors in this lesson are all
real, and were run as an ordinary user. **What is not here is Windows** — the
services, the registry, the CIM classes — and the section on talking to Windows
shows those cmdlets not existing rather than describing output nobody produced.
