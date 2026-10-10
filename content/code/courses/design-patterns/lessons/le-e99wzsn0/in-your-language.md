---
title: Actors in your language
version: 1
---

**Only one of the four languages of the `backend` track has a mainstream actor library, and the
language most famous for actors is not among the four.** That is worth knowing before reaching for
a framework: in JavaScript, Go and Python, the actor model is usually a design you apply with the
tools the language already has, the way section 04 did with a thread and a queue.

| your language | actors | the nearest built-in |
|---|---|---|
| Java (and Scala, Kotlin) | Akka, and Apache Pekko, its open-source fork | threads and `BlockingQueue`, as in section 04 |
| Go | none in the standard library; Proto.Actor and Ergo exist | goroutines and channels |
| JavaScript / TypeScript | none mainstream | Web Workers and Node's `worker_threads`, which talk only by `postMessage` |
| Python | Pykka and Thespian, outside the standard library | `threading` with `queue.Queue`, `multiprocessing`, `asyncio` tasks with queues |

## Java: Akka and Pekko

Akka brought Erlang's model to the JVM in 2009 and is the most complete actor toolkit outside
Erlang: typed actors, supervision, clustering, persistence. Its typed API makes the shelf look like
this, with the reply types and the `withOneLess` helper left out:

```java
sealed interface ShelfMessage {}
record Lend(String title, ActorRef<LendResult> replyTo) implements ShelfMessage {}

Behavior<ShelfMessage> shelf(Map<String, Integer> copies) {
    return Behaviors.receive(ShelfMessage.class)
        .onMessage(Lend.class, msg -> {
            int left = copies.getOrDefault(msg.title(), 0);
            if (left == 0) {
                msg.replyTo().tell(new Refused(msg.title()));
                return Behaviors.same();
            }
            msg.replyTo().tell(new Lent(msg.title()));
            return shelf(withOneLess(copies, msg.title()));
        })
        .build();
}
```

Two things differ from the Python. The message carries its reply address as an `ActorRef`, the
"tell me how it went" design of section 05. And the state is not a field: the behaviour returns the
behaviour for the next message, built with the new copies, which is Hewitt's third rule written
literally and lesson 15's immutability applied to an actor. In 2022 Lightbend moved Akka to a
source-available licence that charges larger companies, and the Apache Software Foundation forked
the last open version as Pekko, with the same API under `org.apache.pekko`.

## Go: goroutines, channels and the near cousin

A goroutine that owns some state and reads requests from a channel is an actor in everything but
name, and it is idiomatic Go. The Go proverb says it directly: *do not communicate by sharing
memory; share memory by communicating*.

```go
type lend struct {
	title string
	reply chan bool
}

func shelf(copies map[string]int, requests <-chan lend) {
	for req := range requests {
		ok := copies[req.title] > 0
		if ok {
			copies[req.title]--
		}
		req.reply <- ok
	}
}
```

The model behind channels is Tony Hoare's *communicating sequential processes*, from 1978, and it
differs from actors in one place worth knowing. **An actor has a mailbox and an address; a
goroutine is anonymous and talks through named channels.** Any goroutine holding the channel can
read from it, a channel can be shared by many readers, and an unbuffered send waits until somebody
receives, where an actor's tell never waits. Supervision is not built in either: a panic in a
goroutine that nobody recovers ends the whole program.

## JavaScript and TypeScript: one thread, and workers

A single Node.js process or browser tab runs your JavaScript on one thread, so the race of section
02 cannot happen between two lines of plain JavaScript; it reappears across `await`, where another
handler can run between the check and the act. For real parallelism, Web Workers and Node's
`worker_threads` each run a separate interpreter with its own memory, and they communicate with
`postMessage`, which copies the message. That is location transparency's discipline enforced by
the platform: a worker is an actor without the supervision.

## Erlang and Elixir: where the model lives

Neither is a `backend` language here, and both are worth an afternoon. Erlang was built at Ericsson
in the late 1980s for telephone switches that had to keep running for years, and its processes are
the actor model with every rule enforced: separate memory, copied messages, links that report a
crash to another process, and OTP's supervisors, whose strategies section 06 named. Elixir runs on
the same virtual machine with a friendlier syntax. A single machine can hold millions of their
processes, because a process starts with a heap of a few kilobytes. If the supervision section made
sense, Joe Armstrong's thesis, *Making reliable distributed systems in the presence of software
errors*, from 2003, is the original argument and reads well.

## What carries over

Whatever you write in, the decisions are the same five. Who owns this state? What messages change
it? What does a sender do while it waits, if it waits at all? Who restarts the owner when it fails,
and what state does the fresh one start from? And what happens to a message that does not arrive?
Lesson 18 asks the same questions about threads and locks, where the answers are harder because
the state is shared.
