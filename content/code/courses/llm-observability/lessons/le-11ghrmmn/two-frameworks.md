---
title: Two frameworks, and what they are made of
version: 2
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
where there is one, the expected answer. The forty-eight replies of lesson 10 carry all four, which is why
both frameworks can grade them without anything being collected again.

## Installing them, and three things to know first

Both go into the course's environment, with two settings first:

```sh
cat >> ~/llmobs/bin/activate <<'EOF'
export DEEPEVAL_TELEMETRY_OPT_OUT=YES
export RAGAS_DO_NOT_TRACK=true
EOF
source ~/llmobs/bin/activate
pip install deepeval==4.2.8 ragas==0.3.1 langchain-community==0.3.31 langchain-openai==1.6.7 pillow==12.3.0 rapidfuzz==3.14.6
```

**Both send telemetry by default.** DeepEval and RAGAS each report anonymous usage to their makers
unless told not to, and the two lines added to `activate` tell them not to. Lesson 2's reasoning is
why: an evaluation library runs over customers' words, and what it sends out of the machine is a
question to settle before the first run, not after.

**DeepEval keeps every test case on disk.** It writes a `.deepeval` folder beside the script, and its
latest run there holds each input, output and retrieval context in full. That is customers' text in a
file nobody thinks of as data: it belongs in `.gitignore` and under the same retention as the traces.

**RAGAS 0.3.1 does not import as its own requirements install it.** It imports a chat model that
`langchain-community` removed in 0.4, and it uses two packages, `pillow` and `rapidfuzz`, without
declaring them. The newest RAGAS, 0.4.3, would pull the OpenAI client back from 3.24 to 1.x, under
every other program in this course. So the line above pins `langchain-community` to 0.3.31 and adds
the other two, and `langchain-openai` is how RAGAS reaches a model. An evaluation framework is a
dependency like any other, and it is often the one with the most dependencies of its own.
