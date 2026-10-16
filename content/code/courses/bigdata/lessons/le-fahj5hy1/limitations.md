---
title: What MapReduce made hard
version: 1
---

**MapReduce solved the problem it was built for: one pass over a very large file, on machines that
fail, written by programmers who had never written distributed code.** It was not built for what
people went on to ask of it, and four limits drove them to replace it.

**Every multi-step question is several jobs.** A join followed by a grouping followed by a sort is
three jobs, each with its own startup, its own read from HDFS and its own replicated write. Nothing
links them except files, so nothing can optimise across them. A tool to chain jobs was the first
thing every team wrote.

**Iteration is ruinous.** The previous section's arithmetic, applied to an algorithm that runs the
same step fifty times: fifty reads of the input, fifty replicated writes, fifty startups.

**Latency is in minutes.** Even a small job on a real cluster spent most of a minute being scheduled
and starting processes. Fine for a nightly batch, useless for an analyst asking a question and
waiting for the answer.

**Everything is written as a map and a reduce.** A filter, a join, a top-ten and a window over time
all have to be expressed in those two shapes, by hand, in Java in the common case. The intent of the
program disappears into the plumbing, and so does any chance for the framework to see that two steps
could be merged or one skipped.

What came next attacked these from two sides. **Higher-level languages compiled into MapReduce
jobs**: Hive turned SQL into chains of them (lesson 12), and Pig did the same for a scripting
language. They fixed the expressiveness and kept the cost. **New engines replaced the model
underneath**: Spark, from the University of California, Berkeley, around 2010, kept data in memory
between steps, planned a whole program at once and ran it as one application. The next lesson
starts there.
