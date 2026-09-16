---
title: The pipe, and the idea the rest of this lesson is made of
version: 1
---

A pipe connects one program's stdout to the next program's stdin. That is the entire mechanism, and
it is the reason Unix has hundreds of small commands instead of a dozen large ones.

```
ana@vm:~/work$ cut -d" " -f9 logs/access.log | sort | uniq -c | sort -rn
   1033 200
     70 201
     28 404
     21 500
     18 302
     16 304
      9 401
      5 403
```

**Four programs, none of which knows anything about web servers**, and the answer is every kind of
response this server gave and how many of each. Read it right to left as a series of decisions:

| | |
|---|---|
| `cut -d" " -f9` | keep the ninth space-separated field: the status code |
| `sort` | put identical codes next to each other |
| `uniq -c` | collapse runs, and count them |
| `sort -rn` | order by that count, biggest first |

Nobody wrote a tool for this question. It was assembled in about fifteen seconds from tools that
predate the web.

## The four processes run at the same time

`a | b` does not mean "run `a`, then run `b`". The shell starts **both**, and `b` reads whatever
`a` has produced so far.

That is worth knowing for two practical reasons.

**A pipeline can finish before the first command does.** `head` is the example — lesson 6 section
08's `SIGPIPE`, where `yes | head -2` kills `yes` rather than waiting for it. So `grep something
huge.log | head -5` returns as soon as it has five lines, however large the file is.

**And memory is not the limit.** `sort` on a ten-gigabyte file does spill to disk, but a pipeline
that only filters holds a few kilobytes at a time no matter how much passes through it. The
pipeline above never had more than a buffer's worth of that log in memory.

## `$?` after a pipeline

```
false | true; echo $?          # 0 — the status of the LAST command
```

Lesson 6 section 14 covered this and it is worth repeating here because pipelines are where it
bites: **`$?` is the last stage's status**, so a failure at the front is invisible. `PIPESTATUS` has
all of them, and `set -o pipefail` changes the rule.

## Reduce first

The pipeline at the top could equally be written:

```
sort logs/access.log | cut -d" " -f9 | uniq -c | sort -rn
```

Same answer, and it sorts twelve hundred whole lines instead of twelve hundred short fields. On this
file nobody would notice. On a ten-million-line log it is the difference between seconds and
minutes.

**The habit is: throw away what you do not need as early as possible.** `grep` before `cut`, `cut`
before `sort`, and `head` last if you only want the top few.

The one exception is `grep`: putting it first means it scans whole lines rather than one field, and
that is still almost always the right trade, because it removes lines entirely.

## What a pipe is not

**It is not a file.** Nothing can seek backwards in it, which is why `tail` on a pipe has to read
the whole thing, and why some programs refuse to work in one.

**It carries bytes, not records.** Every tool in this lesson invents its own idea of a line and a
field from the same stream of bytes, which is why they compose at all — and also why a filename
with a space in it breaks a pipeline that assumed whitespace separated things. Section 16 is that
failure, with the fix.

**And it carries stdout only.** Errors bypass it, which is section 03's `2>&1 |`.

## The small set that does most of it

The rest of this lesson is these, and they are worth seeing as one list before meeting them one at a
time:

| | |
|---|---|
| `grep` | keep the lines that match |
| `cut` | keep some columns |
| `sort` | order |
| `uniq` | collapse and count adjacent duplicates |
| `wc` | count lines, words, bytes |
| `tr` | replace or delete characters |
| `sed` | replace patterns, delete lines, print ranges |
| `awk` | all of the above, with arithmetic and conditions |
| `head`, `tail` | the first or last few |
| `xargs` | turn lines into arguments for another command |

**Nine of those ten read stdin and write stdout and do nothing else.** `xargs` is the exception, and
it exists precisely because some commands take arguments instead of input.
