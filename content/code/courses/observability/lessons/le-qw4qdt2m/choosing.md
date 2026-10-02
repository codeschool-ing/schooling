---
title: Automatic, by hand, or both
version: 1
---

The shop uses all three arrangements on purpose, and between them they cover the choice a team
makes for each service:

| | automatic only | by hand only | automatic, plus lines by hand |
|---|---|---|---|
| in the lab | none, after this lesson | storefront, payments, mailer, report | orders |
| covers | every edge an installed library sees | exactly what the code chose | both |
| business attributes | none | yes | yes, on the automatic spans |
| effort | a command and environment variables | every span written and maintained | the few lines that matter |
| changes with | library upgrades | your own releases | both |

**The usual answer is the third column.** Automatic instrumentation is the cheapest way to get the
edges right, consistently and in the conventions' names, and the code adds what only it knows. A
service instrumented entirely by hand, like the storefront, makes sense when it is small, when the
libraries it uses have no instrumentation, or for teaching. That is why lesson 2 did it that way.

The same idea exists outside Python with different machinery. Java's agent is a JAR loaded with
`-javaagent` that rewrites classes as they load. .NET and Node.js have their own launchers and
start-up hooks. There are also tools that observe a process from the kernel, with eBPF, and see its
network calls without touching it at all. **Every one of them stops at the same three places**: it
cannot name a business object, it cannot follow a client it does not know, and it cannot see inside
your own logic.
