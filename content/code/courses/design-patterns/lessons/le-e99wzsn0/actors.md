---
title: "Actors: a mailbox, private state and one message at a time"
version: 1
---

**An actor is an object that nobody calls.** It has state that only it can see, a mailbox where
messages wait, and a behaviour that takes one message out, deals with it completely, and only then
takes the next. Other code never reaches inside it. It sends a message and carries on.

People who meet actors through Akka or Erlang often picture them as threads, and that picture is
off in a way that matters. A thread is a way of running code; an actor is a way of owning state.
An actor runs on some thread when it has messages, and a system with a million actors may have
eight threads between them, because most actors are idle most of the time. What makes something
an actor is the rule about access; the machinery that runs it can vary.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l17-anatomy\" aria-label=\"An actor and the code that talks to it. On the left, three senders, the north desk, the south desk and the website, each send a message with tell, which returns at once. The messages wait in the mailbox, a queue drawn as three slots: GiveBack, Lend and Lend, with the oldest on the right, next to be handled. The mailbox, the behaviour receive and the private state, a dictionary of copies, are inside one dashed boundary, the shelf actor. One message at a time goes from the mailbox to receive, which alone reads and writes the state. Nothing outside the boundary can reach the state.\"><defs><marker id=\"l17-anatomy-dp-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l17-anatomy-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"45.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">north desk</text><path d=\"M140.0 60.0 L205.0 113.8 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"110.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">south desk</text><path d=\"M140.0 125.0 L205.0 130.0 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"175.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">website</text><path d=\"M140.0 190.0 L205.0 146.2 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><text x=\"80.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tell returns at once</text><rect x=\"225.0\" y=\"25.0\" width=\"460.0\" height=\"210.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"240.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the shelf actor</text><text x=\"345.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mailbox</text><rect x=\"250.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GiveBack</text><rect x=\"316.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lend</text><rect x=\"382.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"412.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lend</text><text x=\"412.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">next</text><path d=\"M448.0 130.0 L520.0 100.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper)\"></path><text x=\"480.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">one at a time</text><rect x=\"520.0\" y=\"72.0\" width=\"150.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">receive(message)</text><rect x=\"520.0\" y=\"150.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">_copies</text><text x=\"595.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{'Iracema': 1}</text><path d=\"M595.0 116.0 L595.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\" marker-start=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><text x=\"595.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">private: no reference outside</text></svg>", "caption": "Senders only ever reach the mailbox. Behind it, one piece of code handles one message at a time and is the only one that touches the state."}
```

## The three things an actor may do

Hewitt's definition is short. When an actor handles a message, it may:

1. send a finite number of messages to actors it knows the address of;
2. create a finite number of new actors;
3. decide how it will handle the next message, which is how its state changes.

That is all. It may not reach into another actor's state, and nothing may reach into its own. Its
fields are private in the strongest sense. Python's underscore is a convention; here no other code
even holds a reference to them. Lesson 1 called encapsulation an object keeping its
own promises; an actor is encapsulation that holds even when two threads are involved.

## One message at a time

**Inside an actor, there is no concurrency at all.** Its behaviour is ordinary sequential code:
read a field, check it, change it. The race of the last section needed two pieces of code running
the check-and-act at once, and here there is only ever one. The desks still run at the same time;
what they now do at the same time is put messages in a queue, and a queue is built to take two
puts at once.

This moves the difficulty rather than deleting it. Concurrency now happens between actors, through
messages, and messages arrive in an order nobody fully controls. Two desks that send *lend
Iracema* at the same instant will be served in some order; which one wins is still decided by
timing. What can no longer happen is the shelf ending up at minus one, because the rule about the
shelf runs from beginning to end without interruption.

## Messages are values

A message is data: a title, an amount, a reply address. It should be immutable, and the examples in
this lesson use frozen dataclasses for that reason. If a desk could send a dictionary and then
change it while it waits in the mailbox, two pieces of code would share state again, and the race
would be back by the side door. Erlang makes this impossible by copying every message; Akka asks
you to send immutable objects and trusts you; Python, here, trusts you too.

Values also make messages easy to read. `Lend("Iracema", "north desk")` says what it means without
a method signature to look up, and a log of the messages an actor received is a complete account of
why it is in the state it is in. Lesson 9's event store had the same property for the same reason.

## What you give up

A method call returns a value; a message does not. When a desk needs an answer, such as *how many
copies are left?*, it has to send a question with a reply address and wait for a message back.
Section 05 builds that, and shows how an actor can wait for itself for ever. A call also either
happens or raises; a message can be lost, or the actor can have crashed before reading it. Sections
06 and 07 deal with each. In exchange you get state that cannot be corrupted by interleaving, and a
unit that can be restarted, moved to another process or spread over many machines without its
callers changing. That trade is the model.
