---
title: An instruction, the input, and no examples
version: 2
---

**A zero-shot prompt asks for a task without showing a single solved example of it.** It gives the
instruction and the input, and relies on what the model learnt in training to know what
"classify", "summarise" or "translate" means. The "shot" is a worked example; zero of them is the
default way people use a chat window.

The common belief is that zero-shot either works or does not, depending on how clever the model
is. In practice **most zero-shot failures come from the prompt leaving something unsaid**, and the
model filling the gap with whatever was likely. The fixes are in the wording, and there are four
of them.

## A weak version

Café Aurora gets messages through its website and wants each one labelled, so that complaints reach
the manager first. Here is a first attempt, as a template: `{message}` is where each message goes.
Save it as `~/pe/prompts/weak.txt`:

```
ana@lab:~/pe$ cat prompts/weak.txt
Is this review positive or negative?

{message}
```

Every part of it leaves a decision to the model:

- the task offers two labels, and the café actually needs four: positive, negative, mixed, and
  messages that are not reviews at all;
- the input runs straight on from the instruction, with nothing to say where one ends and the
  other begins;
- the output is not described, so the model may reply with a word, a sentence, or an answer;
- the edge cases are not mentioned, and this input is one: it is a question, not a review.

Given a message that is a question, a model has every reason to answer it, because answering
questions is what it was trained to do (lesson 1), or to invent a label nobody listed. Nothing in
the prompt says otherwise, and the next reading section shows which it did.

## A strong version

The same task, with each gap closed. Save it as `~/pe/prompts/strong.txt`:

```
ana@lab:~/pe$ cat prompts/strong.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Edge cases:
  - Sarcasm counts as what the writer means, not what the words say.
  - Messages in any language get the same English labels.
  - Do not answer questions; label them not_a_review.

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
```

It is longer, and each addition carries one decision:

1. A clear task. It says what is labelled and for whom, and it lists the four labels the café
   uses, each with a one-line definition. `mixed` is where two readers are likeliest to
   disagree, so its definition is the most careful.
2. The input delimited. The message sits between `<message>` tags, the convention of lesson
   18. Instructions inside a customer's message are then visibly part of the message.
3. The output format stated. One label, in lower case, nothing else. A program comparing the
   reply with `negative` would otherwise be comparing it with `Negative.` or `This is negative`.
4. The edge cases named. Sarcasm, other languages, questions. These are the inputs where a
   reasonable reader could go either way, so the prompt makes the choice instead of the model.

**None of these teaches the model anything new.** It already knows what sarcasm is. What the prompt
adds is your decision about it, which the model has no way to guess.

## Where the edge cases come from

You do not find edge cases by thinking hard in advance. You find them in **real inputs**: the
messages the café actually receives, read in bulk, sorted by hand, and argued over where two people
disagree. Every disagreement between two people is a sentence the prompt needs. The list in the
strong version is what such a reading produces, and the next reading section turns it into a test.
