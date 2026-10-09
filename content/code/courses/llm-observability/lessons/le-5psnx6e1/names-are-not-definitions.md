---
title: A name is not a definition
version: 2
---

Every framework has a metric called faithfulness and one called relevance, and the names suggest they
measure the same thing. They do not. The definitions below are read from the source of the versions
that lesson 12 installs, RAGAS 0.3.1 and DeepEval 4.2.8:

| Name | In this course | In RAGAS | In DeepEval |
| --- | --- | --- | --- |
| relevance | the judge's verdict, refusal decided by the answer key | a model writes questions the reply would answer; their mean cosine with the real question, times zero if the reply is noncommittal | the share of the reply's statements a model judges relevant, borderline counted as relevant |
| faithfulness | the judge's score for whether the reply's statements are supported | the share of the reply's statements a model judges inferable from the context | the share of the reply's claims a model does not find contradicted by the context, borderline counted as passing |
| context precision | rank-weighted share of chunks that are gold chunks | rank-weighted share of chunks a model, or a string match, judges useful against a reference | rank-weighted share of chunks a model judges relevant to the expected output |

Three differences are large enough to change a verdict on the same reply:

- **RAGAS scores a noncommittal reply 0 for relevance.** The prompt that asks for the generated question
  also asks whether the reply is noncommittal, and gives "I don't know" as its example. The agreed
  refusal is noncommittal by that definition, so RAGAS fails every refusal, as this course's judge did in lesson 10
  and the rubric does not.
- **DeepEval's faithfulness asks whether a claim is contradicted, RAGAS's whether it can be inferred.**
  A reply that adds a fact the context does not mention, without contradicting it, passes the first
  and fails the second.
- **Borderline is a decision.** DeepEval counts a borderline verdict as passing in both of these
  metrics by default, and offers a setting to count it as failing for faithfulness. The same replies
  can score differently depending on a default most people never read.

None of these is wrong. Each is a definition somebody chose, and a number is only comparable with
another computed by the same definition, on the same replies, with the same judge model. **Two teams
reporting "faithfulness 0.9" may be reporting different things**, and the honest report names the
framework, its version, the metric's class and the model that ran it.

The course's own definitions are in `metrics.py`, a docstring each. Lesson 12 runs both frameworks on
the same forty-eight replies, with `llama3.2:3b` as their judge.
