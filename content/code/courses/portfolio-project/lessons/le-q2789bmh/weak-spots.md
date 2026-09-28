---
title: Naming the weak spots first
version: 1
---

Every project has weaknesses, and the interviewer will find some of them. The only choice you have is
whether they find them or you tell them, and telling them is almost always better.

loanbook's are known and written down: an unexpected error closes the connection instead of answering;
there is no loading state; anybody who opens the page can lend; SQLite limits it to one server. Each is in
the README, lesson 16, or in the retrospective, lesson 21, and each has a sentence ready.

Naming a weakness first does three things. **It shows you saw it**, which is the whole of lesson 1's
*you can explain*. **It sets the terms**: you describe it accurately, with its cost and its fix, instead of
answering a sharper version of it put by somebody else. And **it frees the rest of the conversation**: an
interviewer who has heard you list the gaps stops looking for them and starts asking what you would do next.

Two cautions. **Name the real ones, not the flattering ones.** *My weakness is that I care too much about
tests* is a well-known non-answer, and it reads as one. And **name them with the fix**, not as a confession:
*the page has no loading state; on a slow phone it would show an empty table for a moment, and a Loading
row is the fix* is a weakness and a plan in one breath.
