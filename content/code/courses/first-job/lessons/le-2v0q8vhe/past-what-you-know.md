---
title: When they push past what you know
version: 1
---

At some point the interviewer asks something you do not know: *how would you make it survive a data-centre
failure?*, *what about VLANs for the guest network?* They do this on purpose. **They are finding the edge
of what you know, and watching what you do there.**

Lesson 20 of the portfolio course is the answer, and it is worth repeating here because this is where it is
tested hardest:

1. Say plainly that you do not know. *I haven't set up VLANs myself.*
2. Say what you do know that is nearby. *I know they separate traffic on the same switch, so guests
   wouldn't reach the office machines.*
3. Say how you would find out. *I'd check the switch's documentation and try it in a lab first.*

What costs the most is a confident answer that is wrong. The interviewer knows the answer, hears the guess,
and learns that you would guess in production too.

A design question with an honest edge in it goes well. Nobody expects a junior to know everything; they
expect a junior to know **where their knowledge ends**, and to say so.
