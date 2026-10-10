---
title: One write, many readers
version: 1
---

**A log lets one system write a fact once and lets any number of systems read it, each at its own
pace, without the writer knowing who they are.** Lesson 1 said this is often the main reason a
company adopts Kafka, even for data nobody needs in a hurry. This section says why it works, and
what it replaces.

## What it replaces

A sale at Ponto Final has to reach four places: the stock system, the loyalty scheme, the warehouse
and the accountant. Without a log, the till calls each of them. That looks like four lines of code
and is four ways to fail. If the loyalty scheme is down for maintenance, the till has to choose
between waiting, which stops the queue at the counter, and carrying on, which loses the customer's
points. If the till sends to stock and then crashes before the warehouse, two systems now disagree
about whether the sale happened, and nothing records which of them is right. Lesson 14 calls this
the **dual write** and shows it failing.

It also grows the wrong way. Five shops with a till each and four systems to tell is twenty
connections, each written and maintained by somebody. A fifth system is five more, and every till
has to be changed and redeployed to add it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Left: five tills each connected directly to four systems, stock, loyalty, warehouse and accounts, which is twenty connections. Right: the five tills each write once to one log, and the four systems each read from the log, which is nine connections, and a new system adds one.\" data-fig=\"l2-integration\"><defs><marker id=\"l2-integration-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"52\" x2=\"240\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"52\" x2=\"240\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"52\" x2=\"240\" y2=\"167\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"52\" x2=\"240\" y2=\"217\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"97\" x2=\"240\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"97\" x2=\"240\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"97\" x2=\"240\" y2=\"167\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"97\" x2=\"240\" y2=\"217\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"142\" x2=\"240\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"142\" x2=\"240\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"142\" x2=\"240\" y2=\"167\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"142\" x2=\"240\" y2=\"217\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"187\" x2=\"240\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"187\" x2=\"240\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"187\" x2=\"240\" y2=\"167\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"187\" x2=\"240\" y2=\"217\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"232\" x2=\"240\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"232\" x2=\"240\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"232\" x2=\"240\" y2=\"167\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"80\" y1=\"232\" x2=\"240\" y2=\"217\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"20\" y=\"40\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><rect x=\"20\" y=\"85\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><rect x=\"20\" y=\"130\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><rect x=\"20\" y=\"175\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><rect x=\"20\" y=\"220\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><rect x=\"240\" y=\"55\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stock</text><rect x=\"240\" y=\"105\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">loyalty</text><rect x=\"240\" y=\"155\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">warehouse</text><rect x=\"240\" y=\"205\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">accounts</text><text x=\"175\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">20 connections</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><rect x=\"390\" y=\"40\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><line x1=\"450\" y1=\"52\" x2=\"506\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"390\" y=\"85\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><line x1=\"450\" y1=\"97\" x2=\"506\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"390\" y=\"130\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><line x1=\"450\" y1=\"142\" x2=\"506\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"390\" y=\"175\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><line x1=\"450\" y1=\"187\" x2=\"506\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"390\" y=\"220\" width=\"60\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">till</text><line x1=\"450\" y1=\"232\" x2=\"506\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"510\" y=\"132\" width=\"50\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">log</text><line x1=\"562\" y1=\"152\" x2=\"606\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"610\" y=\"55\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stock</text><line x1=\"562\" y1=\"152\" x2=\"606\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"610\" y=\"105\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">loyalty</text><line x1=\"562\" y1=\"152\" x2=\"606\" y2=\"167\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"610\" y=\"155\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">warehouse</text><line x1=\"562\" y1=\"152\" x2=\"606\" y2=\"217\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l2-integration-ah-8343)\"></line><rect x=\"610\" y=\"205\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">accounts</text><text x=\"545\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">9 connections</text></svg>", "caption": "Without a log, every writer knows every reader. With one, each knows only the log."}
```

With a log in the middle, the till writes each sale once and is finished. Each of the four systems
reads the log, at its own place, the way the stock and loyalty readers did with `minilog.py`. The
connections are now one per system, and a new system is a new reader that changes nothing on the
till.

## What the readers get

Three properties come with the structure, and none of them needs to be built:

- **Each reader goes at its own pace.** The accountant's job reads once a night; the stock system
  reads within a second. Neither slows the other down, because a reader's place is its own, and the
  log does not wait for the slowest. Lesson 16 is about watching a reader fall behind, which is
  called **lag**.
- **A reader can be added later and start from the beginning.** A recommendations system built next
  year can read every sale since the log began, if the log has kept them, the way the loyalty reader
  read from offset 0. How long a log keeps things is a setting, and lesson 3 sets it.
- **A reader can read again.** A loyalty scheme that miscounted points for a week fixes its code,
  moves its place back a week and reads again. This is called **replay**, and lesson 16 does it with
  Kafka's own tools.

The writer gives up something in exchange: it no longer knows whether anybody acted on the event.
A till that needs an answer, such as *was the card accepted?*, still sends a **command** to the
system that can answer, and waits. The log is for facts, and the till's job ends when the fact is
written.

## A queue is a different tool

A message **queue** also sits between writers and readers, and the two are often confused. A queue
hands each message to one of its readers, and once that reader confirms it, the message is deleted.
Several readers on one queue share the work rather than each seeing everything, and there is no
going back to read last week.

| | log | queue |
|---|---|---|
| a message read by one reader | is still there for every other reader | is gone once that reader confirms it |
| a new reader | can start from the beginning | sees only what arrives from now on |
| reading again | move the place back | not possible; the message was deleted |
| several readers | each reads everything, at its own place | share the messages between them |

Neither is better. A queue is the right tool when each message is a piece of work that should be
done once, by whoever is free: resizing an image, sending an email. Lesson 15 takes RabbitMQ and
Amazon SQS apart and says when a queue beats a log. Kafka can also share a topic's messages between
the copies of one program, which lesson 4 calls a **consumer group**, and that is how it does both
jobs at once.
