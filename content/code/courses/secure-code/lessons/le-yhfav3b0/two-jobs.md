---
title: Two checks with two different jobs
version: 1
---

"We already validate that in the form" is one of the commonest sentences in a code review, and it
mixes up two checks that look alike and do different jobs. **Validation in the browser is for the
person filling in the form. Validation on the server is for the system.** A form needs both, for
different reasons, and neither can stand in for the other.

### What the browser's check is for

A patient signing up on Vereda's portal types a name, an e-mail address and a birth date. If the
address has no `@`, the best moment to say so is while the cursor is still in the box: no round
trip, no page reload, no lost typing. HTML gives that for almost nothing. `required`, `maxlength`,
`type="email"`, `type="date"` with `max`, and `pattern` make the browser refuse to send the form
and point at the field.

That is a real benefit, and it is all **usability**. It makes the form faster to fill in, it helps
somebody using a screen reader find the problem when the error is tied to the field, and it saves
the server from answering requests that were going to fail anyway. None of it is a control,
because **the browser belongs to the person sending the request**, not to Vereda.

### What the server's check is for

The server is the one place every request passes through, whoever or whatever sent it. Its check
is the one that decides what is stored, and the rest of the system relies on it. Lesson 2 built
exactly that kind of check at one boundary.

| | in the browser | on the server |
|---|---|---|
| who it serves | the person typing | the system and everybody whose data it holds |
| when it runs | before the request is sent, and only in a browser that runs it | on every request, from anything |
| who controls it | whoever controls the browser | Vereda |
| if it is missing | a slower, more annoying form | wrong or harmful data in the database |
| can it be skipped? | yes, by sending the request without the form | no, it is where the request arrives |

The last row is the one this lesson proves, in the next section, with one command. The rest of the
lesson is about keeping the two checks in step, because a browser that accepts 120 characters
while the server refuses 61 is a form that sends patients into an error they could not have
avoided.
