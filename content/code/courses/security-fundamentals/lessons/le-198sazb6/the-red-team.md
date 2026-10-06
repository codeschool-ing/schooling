---
title: The red team
version: 1
---

**The red team plays the attacker, with permission.** Its job is to find out what a real adversary
could do, by doing it, under rules, before somebody without rules does. Two kinds of work go under
this heading, and they are often confused:

| | penetration test | red team exercise |
|---|---|---|
| **goal** | find as many weaknesses as possible in a defined scope | test whether the organisation detects and responds to a realistic attack |
| **scope** | narrow: one application, one network | broad: whatever a real attacker would use, often including people |
| **who knows** | the defenders usually know it is happening | as few people as possible, so the response is real |
| **length** | days to a couple of weeks | weeks to months |
| **result** | a list of vulnerabilities to fix | a story of what happened and where detection failed |

A penetration test asks "where are the holes?". A red team exercise asks "if somebody came through one
of them, would we notice, and what would we do?". Both are useful, and a small shop needs the first
long before the second.

### The rules are what make it legitimate

What separates a red team from a criminal is not the technique. It is **written authorisation** and
**rules of engagement**, agreed before anything starts:

- the **scope**: which systems, which addresses, which people may be targeted, and which may not;
- the **window**: when the testing happens;
- the **limits**: what is off limits even inside the scope, such as deleting data or disrupting the
  shop's sales;
- an **emergency contact** on each side, and a way to stop everything at once;
- what happens to any real data the testers see.

Testing a system you do not own, or have not been given written permission to test, is a crime in
Brazil as in most countries, whatever the intention. `pentest` lessons 1, 2 and 22 cover the rules,
the authorisation document and the legal limits in detail, and they come before any technique in
that course for a reason.

For the same reason, everything this course shows is done in its own lab, against machines the
course built for the purpose. The red side in this lesson's exercise is ana, testing the shop's own
portal, agreed in advance with the owners.
