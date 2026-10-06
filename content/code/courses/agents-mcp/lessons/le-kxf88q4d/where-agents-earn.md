---
title: Where an agent earns its cost
version: 1
---

The wrong picture is that an agent is the advanced version of any program that uses a model, so a team that is serious about AI builds agents. The measurements in section 05 say otherwise for most of what a shop like Marginalia needs. **An agent is the right tool for one shape of problem: the path to the answer cannot be written down before the work starts.**

That shape turns up in a few recognisable places:

- **Open-ended support cases.** "My parcel says delivered, my neighbour has a box with my name on it, and I was charged twice" is three problems, and which to look up first depends on what each lookup returns. A decision tree for every combination is longer than the code that would let a model choose.
- **Research across sources.** Answering "which of our suppliers changed their terms this year" means reading one thing, deciding what to read next, and stopping when the question is answered. The number of documents is unknown at the start.
- **Code changes.** Finding why a test fails means reading files chosen by what the last file said. Coding assistants that edit and run code in a loop are the most widely used agents there are, because no fixed script finds an unknown bug.
- **Operations triage.** An alert fires; the next query depends on the last graph. A runbook covers the known causes and stops being useful at the first unknown one.

In each case a person doing the job would also decide the next step by looking at the last result. **That is a good test of whether the task has the shape: a written procedure that a competent new employee could follow without judgement is a procedure a workflow can follow too.**

## Where it is overkill

Most requests at Marginalia have a known path. *"Where is my order?"* is one lookup and one sentence. *"How do I reset my password?"* is one article. The nightly stock report is a query and a template. Wrapping those in a loop adds requests, tokens, seconds and a new way to be wrong, and returns the same answer a fixed path would, when it works. Section 05 measures exactly how much it adds.

There is also a middle ground the word "agent" hides. Many useful systems give the model **one** decision, such as which branch to take or what to extract, and keep the rest in code. They read as AI products and are workflows. Section 04 names the common ones.
