---
title: What a platform adds to a trace store
version: 2
---

Every trace in lessons 1 to 5 went to a file, and every question was a Python script over it. That
scales to a week on one machine. It does not scale to a team, and `observability` lesson 11 already put
traces in Jaeger and Zipkin, which draw them for anybody with a browser. So why do LLM applications
have tools of their own?

Because the questions are different. A general tracing backend knows spans, durations and errors. It
does not know that one span was a model call with a prompt and a reply, that its tokens have a price,
that a customer gave its reply a thumbs down, or that the same prompt template has been edited four
times this month. The tools in this lesson and the next are tracing backends with those things built
in:

| what they add | what it is for | where this course built it by hand |
|---|---|---|
| a model call as a first-class thing, with its prompt, reply, tokens and cost | reading one bad answer | lessons 1 and 3 |
| users and sessions | following one person, or one conversation | lessons 2 and 3 |
| **scores** attached to a trace | thumbs, judges, people, all joined by id | lessons 5 and 9 |
| datasets and experiments | running the evaluation set against a change | lessons 13 and 14 |
| prompt management | versioning the prompt outside the code | lesson 14 |

Two of the best-known tools built for this sit at two ends of a choice every team makes.
**Langfuse** is open source under the MIT licence, and can be run on your own machines or used as a
hosted service. **LangSmith** is LangChain's hosted service; installing it on your own machines is
offered to enterprise customers. The rest of this lesson runs the first on your machine, and runs
the second's SDK against a small recorder of your own, because the service itself only runs on
somebody else's.

## What stays the same

Neither tool changes what lessons 1 to 5 said a trace has to carry. A platform shows the attributes
it is given. A trace with no input on its search span is unreadable in Langfuse exactly as it was in
`tree.py`, and a cost computed from the wrong price is wrong on a nicer screen. The work of deciding
what to record is the application's, and the next sections show that the platform's main contribution
to it is a set of names it expects.
