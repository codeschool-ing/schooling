---
title: PlantUML: UML, precisely, from text
version: 1
---

**PlantUML is a text syntax that covers every UML diagram of lesson 2, and more, rendered by a single
Java program.** Where Mermaid is light and approximate, PlantUML is closer to the UML specification:
arrowheads, stereotypes and fragments come out as lesson 2 drew them.

## Getting it

PlantUML is one `.jar` file. Download the version this lesson uses from Maven Central, the public
repository of Java libraries, and check it runs:

```
ana@vm:~/diagrams$ curl -sSLO https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2026.9/plantuml-1.2026.9.jar
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -version | head -1
PlantUML version 1.2026.9 / 18d0aae [2026-10-17 08:34:41 UTC]
```

## The purchase, as a sequence

Save this as `purchase.puml`. It is lesson 2's purchase, written as text:

```
@startuml
participant App
participant API
participant Holds
database DB
participant Gateway
App -> API : POST /bookings
API -> Holds : hold seat 14, 10 min
Holds --> API : held
API -> DB : insert, pending payment
API --> App : 201 Created
App -> API : POST /payments
API -> Gateway : charge card
alt approved
  Gateway --> API : approved
  API -> DB : mark paid
  API --> App : ticket
else declined
  Gateway --> API : declined
  API ->> Holds : release seat
  API --> App : reason
end
@enduml
```

The arrows follow lesson 2's notation: `->` is a synchronous message with a filled head, `-->` a
dashed reply, `->>` an asynchronous message with an open head. `alt` and `else` open the fragment;
`end` closes it. Render it as SVG:

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -tsvg purchase.puml
ana@vm:~/diagrams$ ls -l purchase.svg
-rw-rw-r-- 1 ana ana 13716 Oct 23 02:06 purchase.svg
```

## A diagram in the terminal

PlantUML can also draw a sequence diagram as text, which is useful in a terminal or in a code review
comment. This is the first request of the purchase alone. Save this as `hold.puml`:

```
@startuml
participant App
participant API
participant Holds
App -> API : POST /bookings
API -> Holds : hold seat 14, 10 min
Holds --> API : held
API --> App : 201 Created
@enduml
```

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -tutxt hold.puml
ana@vm:~/diagrams$ cat hold.utxt
┌───┐             ┌───┐                  ┌─────┐
│App│             │API│                  │Holds│
└─┬─┘             └─┬─┘                  └──┬──┘
  │ POST /bookings  │                       │
  │────────────────>│                       │
  │                 │                       │
  │                 │ hold seat 14, 10 min  │
  │                 │──────────────────────>│
  │                 │                       │
  │                 │         held          │
  │                 │< ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
  │                 │                       │
  │   201 Created   │                       │
  │< ─ ─ ─ ─ ─ ─ ─ ─│                       │
  │                 │                       │
┌─┴─┐             ┌─┴─┐                  ┌──┴──┐
│App│             │API│                  │Holds│
└───┘             └───┘                  └─────┘
```

The text renderer is a convenience, not a replacement: it handles plain messages well and draws
fragments such as `alt` poorly, which is why the full purchase above was rendered as SVG.

## Checking without rendering

`-syntax` asks PlantUML only whether a file parses, reading it from standard input. Break
`hold.puml` by doubling the arrow on its second message, `API -> -> Holds`, save it as
`broken.puml`, and check both:

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -syntax < hold.puml
SEQUENCE
(3 participants)
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -syntax < broken.puml
ERROR
5
Syntax Error? (Assumed diagram type: sequence)
```

The first answer names the diagram type it found and what is in it; the second says `ERROR`, the
line, counted from the first line after `@startuml`, and what PlantUML assumed it was reading.

**Draw it yourself.** Write lesson 2's class diagram of the booking aggregate in PlantUML, with the
composition from Booking to Ticket and the navigable association from Ticket to Trip, and render it.
Check that the diamond lands on the Booking end. The version used here lays out class diagrams on its
own; older PlantUML versions needed Graphviz installed for them.
