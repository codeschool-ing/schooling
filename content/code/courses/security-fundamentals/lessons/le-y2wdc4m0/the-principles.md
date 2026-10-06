---
title: The principles
version: 1
---

Zero Trust is usually summed up as **"never trust, always verify"**. The slogan is accurate and
too short to act on. NIST SP 800-207 states the idea as a handful of tenets; grouped, they come to
four principles that a beginner can apply.

**1. Location grants nothing.** Being on the office network, on the VPN or in the server segment is
not evidence of anything. A request from inside is treated exactly like a request from outside: it
has to show who it is and that it is allowed. The network still matters, because segmentation from
lesson 5 still limits what an attacker can reach, but it stops being the thing that **decides**
access.

**2. Every request is verified, every time.** Access is decided per session, or per request, from
current information. A login at 9 a.m. does not mean the same person is at the keyboard at 4 p.m.
on a different device in a different country. The decision uses **who** is asking (identity, with a
strong login, usually MFA from lesson 9), **what** they are asking from (is it a device the company
manages, is it up to date), and **the context** (the time, the place, how unusual the request is).

**3. Least privilege, per request.** The answer to a request is access to that one resource, not to
the network it sits on. Lesson 6's principle, applied at the granularity of a single page or file
instead of a whole account.

**4. Assume breach.** Design as though an attacker is already inside somewhere, because one may be.
That means limiting how far one compromised account or device can reach, encrypting traffic even
between internal machines, and **watching**: every decision is logged, and the logs are what tell a
defender that ana's account is asking for things from a country she has never been to.

### What the principles do not say

They do not say "trust nobody" about people. Zero Trust is about the **mechanism** of trust: it
replaces an assumption made once, at the network edge, with a decision made on every request from
evidence. Staff are trusted exactly as much as before; what changes is that the system checks it is
really them each time.

They also do not say "remove the firewall". The perimeter and the segments of lesson 5 are still
layers in the sense of lesson 4. Zero Trust adds a decision point in front of every resource; it
does not take the other layers away.
