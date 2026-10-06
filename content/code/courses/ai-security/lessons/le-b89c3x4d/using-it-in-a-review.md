---
title: Using the list in a review
version: 1
---

The list is most useful at one moment: when a feature is about to ship and somebody has to say what
could go wrong with it. The method is the same as lesson 1's inventory, with OWASP's names as the
rows.

## Two rows with nothing in them

```
ana@lab:~/guard$ guard owasp --uncovered
LLM04 Data and Model Poisoning           NOT COVERED IN THIS LAB
LLM08 Vector and Embedding Weaknesses    NOT COVERED IN THIS LAB
10 categories, 2 with no control in this lab
```

*Data and model poisoning* (LLM04) and *vector and embedding weaknesses* (LLM08) both concern the data a
model learns from or retrieves from: a training set or a vector store that somebody tampered with, or
that leaks what it holds. Tarefa's assistant as built in this lab retrieves nothing beyond three help
centre pages written by Tarefa, so the exposure is small today. **A small exposure is still a row**,
and lesson 6 of this course is about exactly these two.

## A review, row by row

For a feature under review, each of the ten gets one of three answers, the same three as in lesson 1:

- **a control**, named, with the lesson or the code that provides it;
- **not applicable**, with the reason: an assistant with no tools has no excessive agency to review,
  and the reason is written so that it is revisited the day it gets one;
- **an accepted risk**, with who accepted it and until when.

A review that ends with ten answers, three of them *accepted risk*, is a better review than one that
ends with ten ticks. It says where the work is.

## The list will change

The 2025 edition reorganised the 2023 one: some entries were merged, *system prompt leakage* and
*vector and embedding weaknesses* were added, and *misinformation* replaced the narrower *overreliance*.
The next edition will change again, because the applications change. Keep the mapping in the
repository, like the inventory, and update it when OWASP does; the controls do not depend on the
numbers, and a reviewer who knows what each control does can place a new category in an afternoon.
