---
title: What the person is told, and when
version: 1
---

**An offline-first screen shows a change as done the moment it is written locally, and it owes the
person a clear word later if the server says no.** That pattern is called an **optimistic** update:
the app acts as if the server will agree, because it nearly always does. The hard part is the case
where it does not, because by then the person has moved on.

## The two mistakes

**Pretending.** The screen shows every row the same way, `pending` or not, and a session that never
reached the server looks identical to one that did. The person changes phone a month later and
finds a week missing. Nothing on any screen ever told them.

**Shouting.** The screen puts a banner on every pending row, or a spinner beside it. On a train,
every session the person adds raises an alarm about something that is normal. They learn to ignore
the banner, and then they ignore the one that mattered.

The planner's middle path is the one the previous section printed: a quiet `waiting to send` beside
a pending row, `saved` once it is accepted, and a sentence with the server's reason when it fails.

## An error that arrives after the fact

The 300-minute session failed when the sync ran, and nothing tied that moment to the moment it was
typed. That is the ordinary shape of an offline failure, so the message has to stand on its own:

- **say which item**, by what the person sees, the date and the course, rather than an id;
- **say why**, in the server's words if they are words a person can act on;
- **say what to do**: change the length, or delete the session;
- **keep the row** until the person decides. Deleting it for them throws away the one thing they
  typed.

On a phone the message goes where the person will see it next: a mark on the row, a count on the
tab, and, if the app runs in the background, a notification. Which of those a platform allows when
the app is not open is lesson 16.

## When not to be optimistic

An optimistic update is a promise that the server will agree. **Make it only where a refusal is
rare and cheap to fix.** A study session meets both. Buying a course does not: the payment is the
server's to accept, a refusal is common (a card declined), and showing "bought" first would be a
lie that costs money. Those operations wait for the server and say so, with a spinner that is
telling the truth. Lesson 10 is the payment that was sent twice, which is what happens when such
an operation is retried without care.
