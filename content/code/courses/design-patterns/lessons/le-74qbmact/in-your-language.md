---
title: Streams in your language
version: 1
---

**Every language of the `backend` track has a way to push values, and they differ most in what
they do about backpressure.** The vocabulary of this lesson, observable, operator, hot and cold,
the four strategies, transfers to all of them. What does not transfer is the default: some
libraries apply backpressure for you, some leave it to you, and one leaves it out on purpose.

| your language | push streams | backpressure |
|---|---|---|
| JavaScript / TypeScript | RxJS: `Observable`, `pipe`, about a hundred operators | none in RxJS: lossy operators such as `throttleTime` and `sampleTime` instead. Node.js streams have it: `write()` returns `false` when the buffer is full |
| Java | Reactor (`Flux`, `Mono`, under Spring WebFlux) and RxJava | demand through `request(n)`, the Reactive Streams rules, plus `onBackpressureBuffer`, `Drop` and `Latest` |
| Go | channels and goroutines; no observable in the standard library | a buffered channel blocks the sender when full; `select` with `default` drops |
| Python | `asyncio` queues and async generators; RxPY, the `reactivex` package, outside the standard library | `asyncio.Queue(maxsize=n)` and `queue.Queue(maxsize=n)` block |

## TypeScript: RxJS

`operators.py` in RxJS is almost a transliteration, because our `pipe` was modelled on it:

```ts
import { from, filter, map, scan } from "rxjs";

from(returns).pipe(
  filter((r) => r.daysLate > 0),
  map((r) => r.daysLate * 50),
  scan((total, cents) => total + cents, 0),
).subscribe((total) => console.log(`fines so far: ${total} cents`));
```

**RxJS has no `request(n)`, and that was decided on purpose.** Its home is the browser, where
most sources are hot and cannot be slowed down: a user does not click more slowly because a
handler is busy. So its answers are the lossy strategies of the last section, under names that
describe time: `throttleTime(1000)` lets one value through per second and drops the rest, and
`sampleTime(1000)` emits the latest value once a second, which is *latest* with a clock. Angular
uses RxJS throughout, so this is the first reactive code many TypeScript developers meet.

## Java: Reactor and the Flow interfaces

```java
Flux.fromIterable(returns)
    .filter(r -> r.daysLate() > 0)
    .map(r -> r.daysLate() * 50)
    .scan(Integer::sum)
    .subscribe(total -> System.out.println("fines so far: " + total + " cents"));
```

Java is where backpressure is most fully built in. Reactive Streams defines four interfaces,
`Publisher`, `Subscriber`, `Subscription` and `Processor`; Java 9 copied them into
`java.util.concurrent.Flow`, and Reactor and RxJava implement the same contract through the
original `org.reactivestreams` package. Between stages, an operator such as `publishOn` asks
upstream for a batch, 256 values by default, and asks for more only as the stage below consumes
them, so a slow stage slows the source without anybody writing a queue. A lambda passed to
`subscribe` asks for everything at once; a subscriber that wants to set its own pace extends
Reactor's `BaseSubscriber` and calls `request(1)` itself.
RxJava keeps two types apart for this reason: `Flowable` honours demand and `Observable` does not,
and the documentation says to use `Observable` only for sources that cannot be slowed, like UI
events.

## Go: channels are the bounded queue

Go has no observable, and most Go programmers would say it does not need one. A goroutine that
reads from one channel and writes to another is an operator, and a chain of them is a pipeline. A
buffered channel is exactly the queue of `blocking.py`, with the blocking built into the language:

```go
scans := make(chan int, 3) // a send waits while three scans are queued

select {
case scans <- scan:
default:
	dropped++ // full: drop this scan and count it
}
```

A plain `scans <- scan` is *block*. The `select` with a `default` case is *drop*, because `default`
runs when no other case can proceed. *latest* takes a few more lines: drain the channel without
blocking, then send. Lesson 17's actors and lesson 18's concurrency come back to goroutines from
the other side.

## Python: what the standard library gives

The course uses no packages, so this lesson built its observable by hand. In real Python code, the
standard library's push tools are `asyncio`: an `asyncio.Queue(maxsize=n)` between two coroutines
is `blocking.py` without threads, and an async generator, consumed with `async for`, is a pull
source whose values arrive later. RxPY, published on PyPI as `reactivex`, is the ReactiveX family's
Python member, with the same operators as RxJS. It is a reasonable choice when a program really is
a network of event streams, and a lot of machinery for a program that has one queue.

## What carries over

Whichever language you use, the decisions of this lesson are the same four questions. Does the
source push or can it be pulled? Is it hot or cold? When the consumer falls behind, does the
producer wait or does a value go? And if a value goes, who counts it? The libraries answer the
mechanics. Those four answers are the design, and they belong in the code review whatever syntax
they are written in.
