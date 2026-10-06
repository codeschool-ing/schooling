---
title: Judging with a model
version: 1
---

When the replies are paraphrased, nothing as simple as a substring can say whether they are right. The
common answer is to ask another model: give it the question, the expected answer and the reply, and
ask whether the reply is correct. It is called **LLM-as-judge**, and it is how most teams measure
answer quality at scale.

**It was not run here.** extract-1 cannot judge anything; it copies sentences. No real model was
reachable from the lab. What follows is the method, the prompt as one might write it, and the cautions,
without results. `prompt-reliability` lesson 13 measured judges in its own lab and is the place to
see one work.

## A judge prompt

A judge prompt is short, asks one question, and constrains the answer to something a program can
read:

```
You are checking an answer from a customer support assistant.

Question: {question}
Expected answer, from the documents: {expected}
Assistant's answer: {reply}

Does the assistant's answer state the same fact as the expected answer,
without adding anything that contradicts it? Ignore wording and length.
Reply with one word: CORRECT, INCORRECT or REFUSED.
```

The expected answer comes from the test set, which is why every question there should carry the passage
that answers it and not only a few words. The judge then compares meaning against meaning, which is
the comparison a fact cannot make.

## What judges get wrong

Studies of model judges, and the measurements in `prompt-reliability`, keep finding the same biases:

- **Position**: asked to compare two replies, a judge tends to prefer the first one shown. Swap them
  and ask again; count a preference only when it survives the swap.
- **Length**: longer replies are judged better more often than they deserve. A rubric that says
  *ignore length* helps and does not cure it.
- **Self-preference**: a judge rates replies from its own model family more kindly.
- **Agreeing with confidence**: a confident wrong reply is marked correct more often than a hesitant
  right one.

None of these makes a judge useless. They make it an instrument that needs calibrating.

## Calibrating the judge

**Label a sample by hand.** Fifty replies marked correct or not by a person who knows the documents.
**Run the judge on the same fifty** and count the agreement. If the judge agrees with the person on
most of them, and its disagreements do not lean one way, use it; if they lean, fix the prompt and
measure again. **Repeat when anything changes**: a new judge model, a new prompt, a new kind of
question. A judge that was calibrated a year ago against a different pipeline measures nothing in
particular now.

And keep the cheap checks running beside it. A fact test that says *wrong* and a judge that says
*correct* is a disagreement worth a person's two minutes.
