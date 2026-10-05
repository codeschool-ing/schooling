---
title: What an embedding is not
version: 1
---

An embedding is good at one thing: placing texts about the same subject near each other. Most of
the mistakes made with embeddings come from expecting more than that. Four expectations are common
and wrong, and each can be measured.

```schooling-example
{
  "language": "python",
  "file": "limits.py",
  "parts": [
    {
      "code": "from minilm import embed\n\npairs = [\n    (\"I want a refund\", \"I do not want a refund\"),\n    (\"I want a refund\", \"Please give me my money back\"),\n    (\"How to return a book\", \"Como devolver um livro\"),\n    (\"How to return a book\", \"How to return a lamp\"),\n]\nfor a, b in pairs:\n    v = embed([a, b])\n    print(f\"{float(v[0] @ v[1]):6.3f}  {a!r} / {b!r}\")",
      "note": "Four pairs, each scored the same way as before: embed both texts and take the dot product. Each pair tests one expectation."
    }
  ]
}
```

```
ana@lab:~/emb$ python limits.py
 0.892  'I want a refund' / 'I do not want a refund'
 0.627  'I want a refund' / 'Please give me my money back'
-0.015  'How to return a book' / 'Como devolver um livro'
 0.492  'How to return a book' / 'How to return a lamp'
```

## Not a reading of what the text says

**I want a refund** and **I do not want a refund** score 0.892, which is higher than *I want a
refund* against *Please give me my money back*, at 0.627. The first pair says opposite things about
the same subject; the second says the same thing in different words. The model rates the opposite
pair as closer.

That is not a defect in this model. Negation, quantities (*one book* against *forty books*) and who
did what to whom change what a sentence asserts while leaving its subject alone, and the subject is
what embeddings capture best. A system that has to know whether the customer wants a refund needs
to read the text, which is a language model's job, or a classifier trained for it, which lesson 4
builds.

## Not language-free

**How to return a book** against its Portuguese translation, **Como devolver um livro**, scores
−0.015: as unrelated as two texts can be. Against *How to return a lamp*, which is about a different
object, it scores 0.492.

All-MiniLM-L6-v2 was trained on English, so Portuguese is to it a string of word pieces it has no
pairs for. A **multilingual** model, trained on pairs across languages, would put the two titles
close together. That is a property you choose when you choose the model, and lesson 9 shows how to
read it off a model's description before you depend on it.

## Not comparable across models

A vector only means something next to other vectors **from the same model**. All-MiniLM-L6-v2 gives
384 numbers and WordLlama gives 256, so the two cannot even be multiplied together. Two models with
the same dimension are no better: the coordinates of one have nothing to do with the coordinates of
the other, and a dot product between them is a number that measures nothing.

So the model is part of the data. Store which model produced every vector, and when the model
changes, **every stored vector has to be computed again**. Lesson 18 prices that.

## Not anonymous

An embedding is not the text, and the text cannot be read back out of it by looking. That has led
people to treat vectors as safe to share when the text is not. Research on **embedding inversion**
says otherwise: a 2023 paper, *Text Embeddings Reveal (Almost) As Much As Text*, trained a model to
rebuild short texts from their vectors and recovered many of them word for word. A vector of a
customer's message is personal data in the same way as the message. Keep it under the
same rules: who may read it, how long it is kept, and when it is deleted.
