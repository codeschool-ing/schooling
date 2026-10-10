---
title: What an incident is, and why to declare one early
version: 1
---

Lessons 5 to 7 counted failures: a deployment failed, service was restored, and a number went into a table. This part of the course, lessons 13 to 18, is about what happens **inside** that number: the hour between something breaking and somebody saying it is fixed, the document written afterwards, the person whose phone rang.

## A working definition

An **incident** is an unplanned event that harms, or is about to harm, the people who use the service, and that needs a coordinated response now. Each part of that sentence does work:

- **unplanned**: a maintenance window that goes as planned is not an incident;
- **harms the users**: a broken internal dashboard is a bug; card charges failing is an incident;
- **coordinated**: more than one person needs to act, or one person needs others to know;
- **now**: it cannot wait for the next planning meeting.

The definition leaves out cause on purpose. An incident can come from a deployment, a provider, a full disk or a spike in traffic, and the response begins before anybody knows which.

## Declare early, and make it cheap

The most damaging habit in incident response is **waiting to be sure before declaring**. Somebody sees something odd, spends twenty minutes confirming it is real and not their mistake, then another ten deciding whether it is "big enough", and only then tells anybody. By then the users have been affected for half an hour and nobody has been coordinating.

The fix is cultural and procedural at once:

- **Declaring must cost almost nothing.** One command in a chat tool, one button, one message to a fixed channel. If declaring needs a form and an approval, people will not do it until they are certain.
- **A false alarm is a success.** An incident declared and closed ten minutes later as "not real" cost ten minutes. An incident not declared until it was obvious cost the users the whole time it was not obvious.
- **Anybody can declare.** A support agent, a developer, a product manager. The person who sees it first is rarely the person who owns the system.

## What declaring sets in motion

Declaring an incident is a switch from normal work to a different mode, with its own rules, which the next three sections set out: **a severity**, which says how much else should stop; **roles**, so that the people responding know who decides and who writes things down; and **one channel**, so that everything said about the incident is said in one place. None of it needs anybody to know the cause yet, which is why it can start in the first minute.
