---
title: The Cheat Sheets, for the how
version: 1
---

ASVS says **what** a well-built application does. It deliberately says little about **how**, because
the how depends on the language and the framework. The how lives in a companion project, the
**OWASP Cheat Sheet Series**: short, practical pages, one per subject, written and reviewed by
practitioners, free to read at `cheatsheetseries.owasp.org`.

A cheat sheet is what to open when a requirement is clear and the right call is not. Each lesson of
this course has one or more:

| lesson | cheat sheet |
|---|---|
| 2, 3 | Input Validation |
| 4, 7 | Cross Site Scripting Prevention |
| 5 | SQL Injection Prevention, and Query Parameterization |
| 8 | Content Security Policy |
| 9 | Cross-Site Request Forgery Prevention |
| 10 | Session Management |
| 11 | Password Storage, and Authentication |
| 12, 13 | Authorization, and Insecure Direct Object Reference Prevention |
| 14 | File Upload |
| 15 | Error Handling, and Logging |
| 16 | Secrets Management |
| 17 | Vulnerable Dependency Management |

### How to read one

A cheat sheet is not a tutorial to follow from the top. Three habits make it useful:

- **Go to it with a question.** "How long should a session last when idle?" is answered in a
  paragraph of the Session Management sheet. Reading the sheet end to end first is slower and
  sticks less.
- **Translate the advice into your framework's call, then check the framework's documentation.**
  The sheets name concepts and often show several languages; the exact Flask, Django or Express
  function is yours to find, which lesson 1 called the half that does not carry across.
- **Prefer the sheet over a blog post.** A sheet is reviewed and updated as advice changes; a post
  from 2017 telling you to hash passwords with SHA-256 is still indexed and still wrong.

### The two together

The working pattern for a team is short: **ASVS for the list, the cheat sheets for the method, the
tests for the proof.** A requirement from ASVS becomes a test that states it, the cheat sheet says
how to make the test pass in a way others have already reviewed, and the test keeps it true.
