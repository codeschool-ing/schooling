---
title: What generators get wrong, and what they refuse
version: 1
---

Two kinds of limit apply to every image generator: **what it cannot do well**, which comes from how it was trained, and **what it will not do**, which comes from the provider's policy. Both have to be designed around, and neither is fixed by prompting harder.

## What comes out wrong

| asked for | what comes back | why |
|---|---|---|
| a sign that says "Used books" | letters that look like letters and spell nothing, or a word misspelt | text was a small, varied part of training pictures |
| five books in a stack | four, or seven | the model learned *a stack*, not a count |
| a hand holding a book | an extra finger, a joint in the wrong place | hands vary enormously and are often partly hidden in photographs |
| a red book on top of a blue one | the colours swapped, or both red | the prompt is one vector; which word binds to which object is loose |
| "a doctor" or "a CEO" | whoever the training data mostly showed | the model reproduces what it saw most |

Newer models, including the ones in lesson 9, render short text far better than early ones did, and some count small numbers reliably. Test the thing you need on the model you use; do not take a limit from an article, this one included, as a fact about next year's model.

The last row deserves more than a fix in the prompt. **A generator's default for a person is a statistical average of its training data**, and in the pictures a shop publishes that average becomes the shop's choice. If people appear in a picture, decide who they are and say so; leaving it to the default is also a decision.

## What is refused

Providers filter both the prompt and the picture. Refusals are typically about sexual content, violence, real people (especially public figures), trademarks and logos, and content that imitates a living artist. The API answers with an error rather than a picture, and lesson 9 shows the shape of that error.

Two of these matter to an ordinary shop every week:

- **Real people.** A picture that looks like an identifiable person, even one made up from a description, can harm that person and expose the shop. Marginalia's style guide says *no faces*.
- **Trademarks and other people's work.** A banner with a recognisable logo, a well-known book cover or a character from a film is someone else's property, generated or not. A cover of *Dom Casmurro* is fine to draw because the novel is in the public domain; the cover a publisher designed for it is not.

## Designing around both

Treat every generated picture as a **draft that a person approves** before it is published, and write down why it was approved. That is not only caution: the approval column of section 04's log is the cheapest place for it, and it is what a shop would show anybody who asked where a picture came from.
