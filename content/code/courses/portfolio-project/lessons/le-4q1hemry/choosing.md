---
title: Choosing one
version: 1
---

Three licences cover almost every portfolio project, and the difference between them is one question:
**what must somebody do if they use your code in their own?**

| licence | they may | they must | typical reason to choose it |
|---|---|---|---|
| MIT | use, change, sell, keep their changes closed | keep your copyright notice and the licence text | the shortest and most familiar permissive licence |
| Apache 2.0 | the same as MIT | the same, plus state changes; it also grants a patent licence | a permissive licence with explicit patent terms |
| GPL 3.0 | use and change | publish their whole program under the GPL if they distribute it | you want every derived work to stay open |

loanbook uses **MIT**, and for a portfolio project that is usually the unremarkable choice: it asks nothing
of a reviewer who wants to try it, a school that wants to run it, or a later employer who wants to see it.
Apache 2.0 is equally fine. The GPL is a real position with good reasons behind it, and choosing it is a
decision you should be ready to explain, lesson 20.

Check one more thing: **the licences of what you use.** loanbook depends only on Python's standard library,
under the Python Software Foundation's licence, which is permissive. A project that uses a GPL library and
distributes itself under MIT has a problem worth finding before a reviewer does. Package managers list
the licence of each dependency; read the list once.
