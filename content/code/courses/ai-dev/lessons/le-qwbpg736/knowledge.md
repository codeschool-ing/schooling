---
title: What it knows, and what it cannot tell it does not know
version: 2
---

A model's knowledge is whatever its training text contained, compressed into its parameters and
frozen on the day training stopped, its **training cutoff**. It does not look anything up while it
writes. When you ask a question, the answer is the likely continuation of your question given
that training, and for a common fact the likely continuation is usually the true one. For a rare
fact, a recent one, or one that was never in the training text, **the loop still produces a
likely-sounding continuation, because producing one is the only thing it can do.**

## A question with an answer, and one without

`next.py` from section 06 shows what the model rates likeliest after a sentence. Here is a
sentence it has read thousands of times, and one it can never have read, because the country was
made up for this lesson:

```
ana@dev:~/shop$ python scratch/next.py "The capital of France is"
 62.7%  ' Paris'
  8.4%  ' located'
  3.7%  '...'
  3.6%  ' not'
  3.2%  ' a'
ana@dev:~/shop$ python scratch/next.py "The capital of the Republic of Veldoria is"
 10.3%  ' the'
  5.8%  ' V'
  3.8%  ' a'
  3.4%  ' located'
  2.7%  ' not'
```

The first is a fact the model learnt: one token with most of the probability. The second is
spread thin. **But it is still a distribution that adds up to 100%**, and the loop draws from it
exactly as before. A distribution has no slot for "I have never seen this". Let the loop run:

```
ana@dev:~/shop$ python scratch/generate.py "The capital of the Republic of Veldoria is" --tokens 30 --temperature 0
The capital of the Republic of Veldoria is the city of Veldoria, which is located in the heart of the Veldorian Valley. The city is known for its rich history, cultural
```

A capital, a valley and a rich history, for a country that does not exist, in the tone of an
encyclopaedia. Every token was the likeliest continuation of the text before it, which is all the
loop ever promised.

Now the same question as a question, through `ollama run`, which wraps it in the model's chat
template the way every chat application does:

```
ana@dev:~/shop$ ollama run llama3.2:3b "What is the capital of the Republic of Veldoria?"
I couldn't find any information on a country called the "Republic of
Veldoria". It's possible that it's a fictional country or not a recognized
sovereign state. If you could provide more context or details, I'll be
happy to help you further.
```

That is better, and the next part of this section says why it is not enough.

## Saying "I don't know" is a habit, not a measurement

The model that invented a valley and the model that declined the question are the same model. The
difference is the chat template: after training on text, this model was trained further on
conversations in which an assistant says it does not know, and the template puts it in that
role. **That is a learnt behaviour, not a measurement.** The model has no reliable internal signal
that tells a fact it learnt from a fact it is reconstructing, so it declines when the question
looks like the ones it learnt to decline, and answers fluently otherwise. A made-up country is
easy to recognise. A made-up function is not:

```
ana@dev:~/shop$ ollama run llama3.2:3b "In Python's standard library, which function in the statistics module computes the harmonic median? Answer with one line of code."
The `statistics.hmean` function in Python's standard library computes the
harmonic mean.
```

**`statistics.hmean` does not exist.** The module's function is `statistics.harmonic_mean`, and
there is no harmonic median in it at all. The answer names a plausible function, changes the
question from median to mean without saying so, and sounds exactly as sure as the answer about
Paris. Ask it yourself and you may get a different wrong answer, or a right one; section 08 is why.

This is called **hallucination**, and for a developer it arrives in three common shapes:

- **an API that does not exist**: a method name that would be the obvious one, on a library that
  named it differently, as above;
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
