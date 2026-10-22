---
title: What is configuration and what is code
version: 1
---

**Configuration is whatever differs between the places a program runs; code is what stays the
same.** The same commit of the links service runs on your laptop, in a test, and on a server, and the
port, the address it listens on, where it keeps its data and the admin key are different in each. The
routes, the validation and the status codes are not. That line is the one to draw, and the principle
that comes from it is usually stated as part of the *Twelve-Factor App*, a short set of rules for
services: **keep configuration in the environment, not in the code.**

| belongs in configuration | belongs in code |
|---|---|
| the port and the address to listen on | the routes and what they answer |
| where the data file lives | the format of the data file |
| the admin key | that deleting needs a key |
| `NODE_ENV`, production or not | what production changes, if anything |
| the address of a database or another service | how to talk to it |

Three things follow from drawing it there:

- **One build runs everywhere.** Nothing is compiled or edited per environment, so what was tested is
  what is deployed, with different values around it.
- **Secrets stay out of the repository.** The admin key in `src/admin.js` since lesson 6 is in every
  copy of the code ever made, and the comment beside it has been saying so. This lesson moves it out.
- **A change of value is not a change of code.** Moving the service to another port is a deploy with a
  new variable, not a commit.

What does *not* belong in the environment is anything that changes how the program behaves in ways a
test would not catch: feature switches nobody tests in both positions, a "debug" mode that skips
checks. A variable is cheap to add and each one is a combination someone has to have run.
