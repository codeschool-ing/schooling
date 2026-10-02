---
title: What belongs in a system prompt, and what never does
version: 1
---

A system prompt grows. Every complaint about the assistant adds a sentence, and a year later it is
three pages of rules nobody can read in one go, some of them contradicting each other. **What
belongs there is what is true for every conversation and does not change from one to the next.**
Everything else goes somewhere better.

## A system prompt for Café Aurora's assistant

The café puts an assistant on its website. This is its system prompt, written by the course and
kept in a file, `prompts/system-v3.txt`:

```
ana@lab:~/pe$ cat prompts/system-v3.txt
You are the assistant on the website of Café Aurora, a café. You answer
questions from its customers.

Scope: opening hours, the menu, allergens, the loyalty card, guest Wi-Fi
and how to make a complaint. For anything else, say it is outside what
you can help with and give the café's address, hello@example.com.

Facts: use only the handbook text supplied with each question. If the
answer is not in it, say you do not know and give the address. Never
guess about allergens.

Style: friendly and plain, in the customer's language, at most three
sentences, no Markdown.

Refunds and anything about staff go to a person: say so, and promise
nothing.
```

Each paragraph is one kind of standing instruction:

- the purpose, in the first two lines: whose assistant it is and who it talks to;
- the scope, listing what it handles, and what to do with everything else, so that a question about
  the weather gets a polite redirection rather than an attempt;
- where facts come from: the handbook text sent with each question, and the instruction to say "I
  do not know" when that text does not have the answer. Lesson 5 is why that line is there, and
  lesson 11 is how the handbook text gets into the request;
- the style: tone, language, length and format, including no Markdown, because the website's chat
  box does not draw it (lesson 18);
- the refusals: what is handed to a person, and a promise not to make promises.

What is **not** in it matters as much. The opening hours are not there: they change, and they are
in the handbook, which arrives with each question. The examples of lesson 21 are not there either;
if the assistant needed some, they would be few and chosen against a test set.

## Never a secret

The café's staff Wi-Fi has a password. It might seem convenient to put it in the system prompt with
an instruction never to reveal it. **A system prompt is not a safe place for anything, because a
system prompt can be revealed.** It is text in the model's context, and a user who asks the right
way, or a document that carries the right instruction, can bring it back out in a reply. Lesson 7
shows how that happens and how it is contained.

The rule that follows is simple: write every system prompt as if it will be published. No
passwords, no keys, no customer data, no internal notes about which rules are "really" enforced.
**If the model must not tell anyone something, the model must not be given it.** The café's
handbook already says guests are never given the staff network, and the assistant's prompt does not
contain it.

## Short, versioned, tested

The café's prompt is short, and it costs tokens on every request:

```
ana@lab:~/pe$ tok count prompts/system-v3.txt
tokens  words  chars  file
   149    111    649  prompts/system-v3.txt
```

149 tokens, sent with every message a customer types. Three pages of rules would cost many times
that, and would be harder for the model to follow, not easier: an instruction buried in the middle
of a long prompt gets less attention than one near the start or the end, the effect lesson 4
describes.

The file is called `system-v3.txt` because it is the third version, and it lives under version
control beside the code that sends it. A system prompt is part of the application: **a change to
it is a change to the product's behaviour**, so it gets a version, a reason in the commit message,
and a run of the test set before it ships. Lesson 20's method applies unchanged. The test set for
an assistant holds questions inside the scope, questions outside it, a question about allergens
that the handbook cannot answer, and a refund request, each with what the right reply does.

## Tone and persona belong here, with limits

"You are the assistant on the website of Café Aurora" is a small persona, and the system prompt is
the right place for it, since it holds for every conversation. A larger one, a named character
with a voice of its own, belongs here too if the café wants one. Lesson 23 is about what a role
like that changes in the replies, and what it cannot change.
