---
title: Who is asking, and what they may do
version: 1
---

**Authentication answers "who is this?" Authorisation answers "may they do this?"** They are two
questions, asked in that order, and an API that runs them together ends up answering the second one
whenever it answers the first.

The common picture is a single gate: you log in, and you are in. It holds for a small site with one
kind of user and stops holding the moment there are two. A partner bookshop that reads the catalogue
and an employee who changes prices have both proved who they are, and only one of them should change
a price. Proving who you are opens nothing by itself; it gives the server a name to make its next
decision about.

The two halves have names worth keeping apart:

| | the question | what it needs | what a failure looks like |
|---|---|---|---|
| **authentication** | who is this? | a **credential**: something that proves a name | 401, "I do not know who you are" |
| **authorisation** | may this one do that? | a rule about the name and the action | 403, "I know who you are, and no" |

A credential is not the name. `ana` is a name anybody can type; the password that goes with it, or a
token the server issued to her, is what proves it. Everything in this lesson is a kind of credential:
how it is sent, how the server checks it, what the server keeps and how it is taken away.

shelf makes the split visible in one place. The file this lesson builds lets every caller that
proves who it is read every book. That is all the authorisation it does, with one exception: an API
key belongs to an application, and an application may not create or delete keys. When a key asks for
the list of keys, the server knows exactly who is asking and still refuses, and the section on API
keys shows that answer.

Where the line falls in the rest of the course:

- lessons 7 to 10 are about the first question: credentials here, sessions and JWT in lesson 8,
  handing access to another application and signing in through another provider in lesson 9, and
  storing passwords in lesson 10;
- lesson 11 is the second: roles, permissions and scopes;
- lessons 12 and 13 are about what happens around both: how often one client may ask, and what
  protects the request on its way.
