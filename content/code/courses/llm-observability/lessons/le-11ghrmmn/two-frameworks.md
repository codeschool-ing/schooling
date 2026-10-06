---
title: Two frameworks, and what they are made of
version: 1
---

**DeepEval** and **RAGAS** are the two open-source evaluation libraries most often met in Python
projects that call a model. Both do what lessons 8 to 11 did by hand, under a shared structure, and
reading that structure is most of learning either.

| | DeepEval 4.2.8 | RAGAS 0.3.1 |
| --- | --- | --- |
| one item to grade | `LLMTestCase`: input, actual output, expected output, retrieval context | `SingleTurnSample`: user input, response, retrieved contexts, reference, reference contexts |
| a metric | a class with `measure()`, a `threshold`, and a `score`, `reason` and `success` after measuring | a class with an async `single_turn_ascore()` returning a number |
| running many | `evaluate(test_cases, metrics)`, or a pytest file run by `deepeval test run` | `evaluate(dataset, metrics)`, returning a table |
| its own metrics | mostly a prompt to a model plus arithmetic | the same, plus a family that needs no model |

The field names differ and the ideas do not: a question, a reply, the chunks the model saw, and,
where there is one, the expected answer. The sixty replies of lesson 10 carry all four, which is why
both frameworks can grade them without anything being collected again.

## Before installing either

Three things in this lab are worth knowing before they surprise a team.

**Both send telemetry by default.** DeepEval and RAGAS each report anonymous usage to their makers
unless told not to; `/etc/llmobs.env` sets `DEEPEVAL_TELEMETRY_OPT_OUT=YES` and
`RAGAS_DO_NOT_TRACK=true`, and lesson 2's reasoning is why. An evaluation library runs over customers'
words, and what it sends out of the machine is a question to settle before the first run, not after.

**DeepEval keeps every test case on disk.** It writes a `.deepeval` folder beside the script, and its
latest run there holds each input, output and retrieval context in full. That is customers' text in a
file nobody thinks of as data: it belongs in `.gitignore` and under the same retention as the traces.

**RAGAS 0.3.1 did not import as installed.** It imports a chat model that `langchain-community`
removed in 0.4, and it uses two packages, `pillow` and `rapidfuzz`, without declaring them. The newest
RAGAS, 0.4.3, would have pulled the OpenAI client back from 3.24 to 1.x, under every other program in
this course. The lab pins `langchain-community` to 0.3.31 and adds the other two, with a comment in
`lab.sh` saying why. An evaluation framework is a dependency like any other, and it is often the one
with the most dependencies of its own.
