---
title: What it knows, and what it cannot tell it does not know
version: 1
---

A model's knowledge is whatever its training text contained, compressed into its parameters and
frozen on the day training stopped, its **training cutoff**. It does not look anything up while it
writes. When you ask a question, the answer is the likely continuation of your question given
that training, and for a common fact the likely continuation is usually the true one. For a rare
fact, a recent one, or one that was never in the training text, **the loop still produces a
likely-sounding continuation, because producing one is the only thing it can do.**

## The small model on a question it has no business answering

`tinylm` was trained on Python's documentation, which never mentions France. Ask it anyway:

```
ana@dev:~/shop$ python lab/next.py "The capital of France is"
context used: 1 tokens
 11.5%  ' a'
  8.0%  ' the'
  5.9%  '\n'
  5.2%  ' not'
  3.8%  ' used'
ana@dev:~/shop$ python lab/generate.py "The capital of France is" --tokens 14 --temperature 0
The capital of France is a string, and
  A binascii.Error is raised if

```

`context used: 1 tokens`: it had never seen `France is`, so it fell back to what follows ` is`
alone, and from there it wrote what follows ` is` in its corpus. It is the same text the greedy
run of lesson 1 section 04 produced after `The default value is`, for the same reason.

**And it gave no sign of any of this.** Here it is on a phrase it has never seen any part of:

```
ana@dev:~/shop$ python lab/next.py "colourless green ideas"
context used: 0 tokens
  3.7%  ' the'
  3.0%  '\n'
  2.9%  ','
  2.4%  '.\n\n'
  2.0%  ' a'
```

With no context at all, it predicts the most common tokens in its corpus. The output is still a
distribution that adds up to 100%, and the generation loop would draw from it exactly as before.
**A distribution has no slot for "I have never seen this".** The lab's script prints how much
context it used because the lab wrote that line; no provider's API returns anything like it.

## The large-model version of the same thing

A large model is far better at this than `tinylm`, and it can say "I don't know", because it was
trained on examples of saying so. That is a learnt behaviour, though, not a measurement: the
model has no reliable internal signal that tells a fact it learnt from a fact it is
reconstructing. So it makes this mistake on exactly the questions where its training text was
thin, and it makes it in the same fluent, confident style as everything else. This is called
**hallucination**, and for a developer it arrives in three common shapes:

- **an API that does not exist**: a method name that would be the obvious one, on a library that
  named it differently;
- **an API that used to exist**: the version of a library from before the training cutoff,
  confidently, for code that runs against the version after it;
- **a package that does not exist**: a plausible import that nobody ever published, which is
  worse than a typo, because anybody can publish it later (lesson 11).

## Working with it

Two habits make most of this manageable, and each one has lessons behind it:

- **Put the facts in the context.** The documentation of the version you use, the actual error
  message, the actual code. A model continuing from the right text is much likelier to be right
  than one recalling the text from training. Lesson 5 is about doing that in a prompt, lesson 6
  about doing it automatically.
- **Check what comes back against something that is not a model.** Run the code, run the tests,
  read the cited source. Lessons 3 and 4 make that the normal way to accept a suggestion, and
  lesson 11 makes it a design rule.
