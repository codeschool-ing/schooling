---
title: Written prompt, prompt tuning, fine-tuning
version: 1
---

It is easy to read the three as steps on one ladder, where serious work starts with a prompt and
graduates to training. They are better read as three places to put the change, each with its own
price. **The question is not which is most advanced but which numbers you are allowed to touch.**

| | written prompt | prompt tuning | fine-tuning (lesson 9) |
|---|---|---|---|
| what changes | the text sent with each request | a few learnt vectors in front of the input | the model's weights, or a part of them |
| what stays fixed | the model | the model | the base you started from |
| what you need | access to the model, by chat or API | the weights, a training set, and hardware to train on | a training set, and either the weights or a provider's training service |
| what it costs | the tokens of the prompt, on every request (lesson 3) | a training run, then almost nothing per request | a training run, and often a higher price per request for a custom model |
| can a person read it | **yes** | no: it is vectors | no: it is weights |
| moving to another model | rewrite and test again | train again from the start | train again from the start |
| how fast you can change it | minutes | a new training run | a new training run |

Read down the columns and one difference stands out: **only the written prompt can be read, and
changed, by somebody without a training set.** Almost everything this course has taught, from
roles to examples to ReAct, lives in the first column.

## Why most people never do it

If you use a model through a hosted API, at the time of writing (2026), you send text and receive
text. You do not hold the weights, so the second column is closed to you: there is no field in the
request where a vector could go. Fine-tuning reaches you only where a provider offers it as a
service, on the models it chooses, and lesson 9 weighed when that is worth it.

So prompt tuning belongs to people who run a model themselves, usually an open-weights model on
their own hardware. For them it has a real advantage over fine-tuning: one frozen copy of the model
can serve many tasks, each with its own small soft prompt swapped in per request, where fine-tuning
would mean a separate set of weights per task.

## Why it is still worth knowing

Two things carry over even if you never train a vector.

First, it shows plainly that **the words in a prompt matter only through what they do to the
model**. The best soft prompt is not a sentence, and a person would never write it. The written
prompts that work best for a model can be odd in the same way, which is why lesson 31 lets a
program search for them rather than trusting the one that reads best.

Second, it puts a name to a claim you will meet in product descriptions: a model "tuned" for a
task. Ask which column it is. A new written instruction, a set of learnt vectors, and changed
weights are three different things, and only the first can be inspected by reading it.
