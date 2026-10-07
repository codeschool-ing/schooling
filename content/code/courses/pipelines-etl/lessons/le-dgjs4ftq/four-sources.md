---
title: Who decides the pace
version: 1
---

A pipeline extracts from somebody else's system, and **the kind of system decides what the
extraction can ask for**. Ponto Final has all four kinds that a pipeline meets:

| source | in the lab | what you get | who decides the pace |
|---|---|---|---|
| **a database** | the shop's PostgreSQL | anything SQL can ask, at any moment | you, within what the source can bear |
| **an API** | the publishers' price API | what its designers chose to expose, a page at a time | the API, by its rate limit |
| **a file** | the distributor's stock file | whatever was written, whenever it was dropped | whoever writes the file |
| **events** | the website's click log | everything that happened, once or more, roughly in order | the world |

Read the last column downwards and the pipeline's control falls away. With a database Ana chooses
what to read, when, and how much. With an API she chooses within limits somebody else set. With a
file she waits for it to arrive and takes what it contains. With events she does not even choose
when: they happen.

**Each source has a failure that the others do not**, and that failure is what this lesson is
about:

- a database read in two statements can describe two different moments;
- an API answers with a page, a refusal, or nothing at all;
- a file can arrive half written, or written differently from yesterday;
- an event can arrive twice, or after events that happened later.

None of them reports these as errors. The torn read returns numbers, the half file loads, the
duplicate event counts. **That is the shape of the problem across this whole course: the
dangerous failures are the ones that succeed.** The sections below produce each one in the lab,
on purpose, so that you have seen it before it happens to you.
