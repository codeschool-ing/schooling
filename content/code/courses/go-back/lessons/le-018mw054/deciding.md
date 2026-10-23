---
title: Choosing, per caller
version: 1
---

The question is never "gRPC or REST" for a whole company. **It is which protocol each kind of caller should
use**, and the answers from this lesson fit in four questions.

**1. Is the caller a browser, or a stranger's program?** Then REST and JSON, section 05: browsers cannot
speak gRPC without a translator, and strangers start with `curl`.

**2. Do you own both ends, and will they live for years?** Two services of your own, deployed by your own
teams, are where a required contract and generated clients pay most: a field renamed in the `.proto` breaks
the build of every client that uses it, instead of breaking production.

**3. Is the conversation a stream?** A scanner sending a queue of tickets, a screen following a count, a
service pushing a feed: gRPC's streams are built in, with flow control and deadlines. REST imitates them,
and lesson 13 shows the imitations.

**4. Is the volume extreme?** Thousands of small messages a second between services, where every byte and
microsecond multiplies: then protobuf's size and speed, section 03, start to count. For an ordinary API whose
answers are compressed and whose time goes into a database, they do not.

**If the first answer is yes, use REST. If any of the other three is yes, gRPC is worth its tooling.** If none
is, REST is the simpler thing to build, debug and hand to the next developer, and simplicity is the default
lesson 5 argued for.

## Signs you chose wrong

**gRPC was the wrong choice** if every caller ends up going through a gateway that turns it back into JSON, if
most debugging sessions start with someone installing `grpcurl`, or if a browser client is the main user.
**REST was the wrong choice** if the client code for an internal service is a pile of hand-written structs
that drift from the server's, if polling loops imitate streams everywhere, or if a field renamed on one side
is found by a customer. Each of these is a migration nobody wants; seeing the signs early is what this lesson
was for.
