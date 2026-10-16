---
title: At least once: process first, and do again what the crash interrupted
version: 1
---

**At least once means every message is processed, and some may be processed more than once.** The
consumer commits only after it has done its work, so a crash leaves the committed offset behind
the work actually done, and the restart repeats everything since the last commit. Nothing is
lost; the interrupted batch is done twice, in part.

This is what almost every Kafka consumer runs, including the ones nobody configured: with
`enable.auto.commit` on, which is the default, the client commits in the background every five
seconds the offsets of what `poll` has already returned, so a crash repeats up to five seconds of
work. It is at least once with a timer instead of a decision.

## The same crash, the other way round

Same program, `least` mode, same crash after 25 sales:

```
ubuntu@stream:~/work$ python crash_consumer.py least --crash-after 25
crashed after 25 sales
ubuntu@stream:~/work$ python crash_consumer.py least
processed 30 sales; nothing more to read
ubuntu@stream:~/work$ wc -l < processed-least.txt
55
ubuntu@stream:~/work$ sort processed-least.txt | uniq -d
car-000024
joa-000021
joa-000022
joa-000023
joa-000025
```

This time the third batch was read and half written when the crash came, but its offsets had
not been committed; the last commit was after the second batch, at 20. The restart began there
and processed 30 sales, 21 to 50. **The file holds 55 lines for 50 sales**, and `uniq -d` names
the five that appear twice: sales 21 to 25, the part of the third batch that was done before the
crash and done again after it. Nothing is missing.

## Why at least once is the usual choice

A lost message is silent. Nothing records that it existed, so nothing downstream can notice its
absence; a missing sale is a total that is slightly too small for ever. A duplicate is
**visible**: it has the same id as a message already seen, and a reader that keeps ids can find
it and drop it. So the industry's habit is to choose the failure that can be repaired, and repair
it at the receiving end. That is lesson 8.

The size of the repair depends on the size of the window. A consumer that commits after every
message repeats at most one message per crash and pays for a commit per message; one that commits
every thousand repeats up to a thousand. Committing is a request to the broker, so it is not free,
and the usual compromise is a batch, as here, or a time.

There is one way to turn at least once into a much worse outcome, and it is worth naming because
it looks like a fix. A program that catches the exception from its processing, logs it and moves
on has made a message disappear on purpose: the commit after the batch covers it. If a message
cannot be processed, it has to stop the consumer or go somewhere a person will look, which is the
dead-letter topic of lesson 16.
