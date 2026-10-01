---
title: How a resolver's cache gets poisoned
version: 1
---

A **resolver** asks other servers for names on behalf of its clients and keeps each answer in a
**cache** for as long as its TTL allows. Every client of the resolver then gets the cached answer
without anybody asking again. That is what makes DNS fast, and it is what makes a false answer in the
cache so valuable: **poison one cache and every client of that resolver is sent to the wrong address
until the entry expires**, without any of them having done anything wrong.

The classic way in is a race. DNS mostly travels over UDP, which has no handshake, and the resolver
accepts the first answer that matches its question. An attacker who can guess when the resolver will
ask sends forged answers, with the real server's address as their source, hoping one arrives first
and matches. To match, the answer has to carry the same **transaction ID**, a 16-bit number, and
arrive at the right **source port** of the question.

The defences stack, and each is worth knowing by what it does:

| defence | what it takes away from the forger |
|---|---|
| random transaction IDs | 1 chance in 65,536 per forged answer, instead of a predictable number |
| random source ports | multiplies the guessing by the number of ports; modern resolvers do this by default |
| not being an open resolver | strangers cannot make the resolver ask the questions at a time they choose (lesson 6) |
| source address filtering | forged answers claiming the real server's address are harder to send (this lesson) |
| **DNSSEC** | the answer is signed; a forged one fails verification whatever the timing |

The first four make forging unlikely. **Only DNSSEC makes it useless**, because it checks the answer
itself instead of how the answer arrived. The next two sections put it on the lab.

Poisoning also has quieter forms that no protocol defends against: a compromised home router that
hands out a malicious resolver, or a changed `hosts` file on one machine. Both are local, and both
show up as one machine resolving differently from its neighbours.
