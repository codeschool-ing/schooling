---
title: Two questions
version: 1
---

People say "login" for everything that happens between typing a password and seeing a page, and
security people say **authentication** and **authorisation**, often abbreviated as authN and authZ,
which look alike and sound alike. They answer different questions, and confusing them is behind one
of the most common flaws in software.

| | question | at the shop's portal | answered by |
|---|---|---|---|
| **identification** | who do you claim to be? | "I am ana" | a username |
| **authentication** | can you prove it? | the password that only ana knows | a password, a second factor, a key |
| **authorisation** | what may you do? | ana may read her own payslip | the portal's rules |
| **accounting** | what did you do? | ana read her payslip, and when | the log |

The four together are called **AAA**, for authentication, authorisation and accounting, with
identification folded into the first.

**Identification** is only a claim. Typing "ana" proves nothing; anybody can type it.

**Authentication** checks the claim against something only the real ana should have. Lesson 9 is
about the three kinds of evidence and why one of them is rarely enough.

**Authorisation** happens after authentication and uses its result. Knowing for certain that the
request comes from ana says nothing yet about whether ana may read bruno's payslip; that is a
separate decision, made by rules about what ana's role, ownership or situation allows.

**Accounting** records what an authenticated identity did, so that lesson 1's accountability is
possible. The portal's log, which appeared in lessons 4 and 7, is its accounting.

### Why the order matters

Authorisation needs authentication first, because a rule like "a person may read their own payslip"
means nothing until the system knows who the person is. The reverse does not hold: a successful
authentication grants nothing on its own. **Being somebody is not permission to do something.**

The error this lesson is about is a system that stops after the first step: it checks that the user
is logged in, and then serves whatever they ask for. Every logged-in user can then read every other
user's data by changing a number or a name in the address. The next two sections show the portal
doing it right, first from outside and then in its code.
