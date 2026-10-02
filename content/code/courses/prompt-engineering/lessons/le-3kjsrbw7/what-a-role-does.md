---
title: What a role changes in a reply
version: 1
---

A role prompt tells the model who to be: "You are a head barista", "You are a patient teacher",
"You are a lawyer reviewing a lease". It is one line, it usually comes first, and in an
application it sits in the system message of lesson 22, since it holds for the whole conversation.

**A role is a way of choosing which kind of text the reply resembles.** A model produces likely
text (lesson 1), and the text it learnt from was written by many kinds of people for many kinds of
reader. A barista explaining coffee to a customer writes differently from a roaster teaching
trainees, and a role line makes one of those styles the likely one to continue.

## Four things a role sets

- The register: how formal, how warm, how many words. A barista at the counter is brief and
  friendly; an instructor is thorough.
- The vocabulary: which terms are used, and which are explained. "Extraction" is ordinary for a
  roaster and needs a gloss for a customer.
- The angle: what the answer is about. Asked why a coffee is bitter, a barista thinks about what to
  do now and an instructor about why it happens.
- The audience the reply assumes: what it takes for granted, and what it stops to explain.

**The fourth is the one people forget they are setting**, and the next reading section comes back
to it.

## The same question, two roles

The question is the same in both: a customer's complaint that the flat white tastes bitter. The
course wrote both prompts and both replies as illustrations; no model was called.

With the role of a barista talking to a customer:

```localised
You are a barista at Café Aurora, talking to a customer at the counter.

Customer: My flat white tastes really bitter today. Why?
```

```localised
Sorry about that! It can mean the shot ran a little too long. Let me
make you a fresh one, and if you'd like it milder I can use oat milk,
at no extra cost.
```

With the role of a coffee instructor teaching new staff:

```localised
You are a coffee instructor at Café Aurora, teaching new staff.

Trainee: A customer said their flat white tasted really bitter. Why?
```

```localised
Bitterness usually means over-extraction: the water spent too long
in contact with the coffee, or the grind was too fine. Check the
shot time first. If it is running long, coarsen the grind slightly
and pull a test shot before serving.
```

Both are reasonable, and they are not interchangeable. The first apologises, offers a remedy and
mentions a fact from the café's handbook. The second uses the word "over-extraction", gives a
cause and a procedure, and apologises to nobody. **Neither role added a fact the other lacked**:
the cause of bitterness is the same in both, and it came from what the model learnt in training.
What changed is which part of that knowledge was put forward, in which words, for whom.

## A role is cheap, and that is its strength

One line changes the register of every reply that follows. That is a good trade wherever the
register matters: a website assistant that should sound like the café, a tutor that should
explain rather than show off, a reviewer that should be blunt. The café's system prompt in lesson
22 has a small role in its first line for exactly that reason.

It is not a substitute for saying what you want. "You are a concise assistant" is a weaker way of
writing "answer in at most three sentences", and the explicit version can be tested against a
reply. **Use a role for the voice, and an instruction for anything you will check.**
