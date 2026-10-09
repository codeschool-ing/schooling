---
title: What an evaluation set is
version: 2
---

Lessons 8 to 12 graded the same twenty-four questions again and again: `data/eval.jsonl`, which lesson
8 wrote. Each line is a **case**: an id, a question, the chunks of the documents that answer it
(`gold`) and the facts a right answer contains. Five of the twenty-four have no gold and no facts; the
right answer to those is the refusal.

That file is an **evaluation set**, and it is a different thing from anything lesson 9 sampled. A sample
of traffic says how the assistant did last week, on whatever customers happened to ask. An evaluation
set asks **the same questions of every version**, so that two versions can be compared on equal terms; that is lesson 14's job. It also lets a build fail when one gets worse, which is lesson 15's.

Four properties make a set fit for that, and this lesson is about keeping them:

- **Every case has an id that never changes and is never reused.** Results, labels and comparisons
  name cases by id. A renumbered set silently compares different questions.
- **Every expected answer is true of the documents.** A case whose fact the shop has since changed
  fails every version, and soon nobody trusts the failures.
- **The set holds nobody's data.** It is copied into every run, every report and every pull request,
  so whatever is in it goes everywhere.
- **The set is pinned.** Every result says which version of the set it came from, and a version is a
  fixed file whose hash can be checked.

The twenty-four cases of lesson 8 were written by somebody reading the documents. That is a good start and a
poor finish: they are the questions somebody thought customers would ask, phrased the way somebody
writes. The next section adds the questions customers did ask.
