---
title: Six ways things go wrong
version: 1
---

"What can go wrong?" asked of a room produces whatever the room remembers: injection, because
everybody has heard of it, and whatever hurt somebody last month. The list has no shape, so there is
no way to tell what it missed. **STRIDE** gives it a shape. It was written at Microsoft in 1999 by
Loren Kohnfelder and Praerit Garg. It is still the most used way of answering the second question,
because it does one thing well: **it turns "what can go wrong" into six narrower questions, each the
violation of a property you want the system to have.**

| letter | threat | the property it violates | at the portal |
|---|---|---|---|
| **S** | **spoofing**: pretending to be somebody or something else | **authentication** | a request pretending to come from the payment gateway |
| **T** | **tampering**: changing data or code without permission | **integrity** | an exam PDF replaced by a different file |
| **R** | **repudiation**: denying an action, with no way to show otherwise | **non-repudiation** | a clinical note edited, and no record of who changed it |
| **I** | **information disclosure**: data reaching somebody not allowed to read it | **confidentiality** | a patient downloading another patient's exam |
| **D** | **denial of service**: making the system unavailable to people who need it | **availability** | uploads filling the storage until exams can no longer be sent |
| **E** | **elevation of privilege**: doing what your role does not allow | **authorisation** | a stolen receptionist password reaching every record |

The right-hand pairing is the useful half. Three of the six are the CIA triad from
`security-fundamentals` lesson 1: confidentiality, integrity, availability. The other three are
about people: are they who they say (authentication), can they deny what they did
(non-repudiation), and are they allowed to do it (authorisation). Each letter, then, is a question
you ask of an element: *could somebody break this property here?*

### The letters overlap, and that is fine

A real attack is several letters in sequence. Phishing a receptionist (S) leads to reading every
record (E, then I). Spending time deciding whether a threat is "really" spoofing or elevation is
time not spent finding the next one. The categories are a prompt for finding threats, not a filing
system; file each threat under the letter that made you think of it and move on.

### What STRIDE is not

**It is not a list of attacks.** "SQL injection" is not a STRIDE category; it is a way to cause
tampering, disclosure or elevation, depending on what the query does. The `attacks-threats`
course catalogues techniques. STRIDE asks which property each part of your system could lose,
which is a question about your design rather than about attackers' tools.

**It does not rank anything.** A STRIDE list says what can go wrong. How likely each item is and
what it would cost are lessons 9 to 11, and a threat found with STRIDE carries no score until
then.
