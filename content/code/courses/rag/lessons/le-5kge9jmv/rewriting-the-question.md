---
title: Rewriting the question
version: 2
---

Everything so far took the question as the user typed it. Often that is the weakest link: the
question is short, refers to something said earlier, or uses words no document uses. **Rewriting the
question** before searching is cheaper than any improvement to the index, because it costs one step per
question and changes nothing that was stored.

## A follow-up question

In a conversation, people ask the second question in terms of the first. After *How many days do I
have to return a printed book?* comes *And for e-books?*, which means something only to somebody who
read the first question.

```
ana@vm:~/rag$ python show.py vector "And for e-books?"
1    0.585  E-books and audiobooks > Where e-books can be read  | E-books open in the Marginalia app for phones an
2    0.574  E-books and audiobooks > Audiobooks  | Audiobooks are sold separately from e-books and 
3    0.563  E-books and audiobooks > Refunds for e-books  | An e-book that is faulty, for example with missi
4    0.548  E-books and audiobooks > Where e-books can be read  | You can use the same account on up to six device
5    0.540  E-books and audiobooks > Reading  | In the app, tap the middle of the page and choos
```

The search did what it could with the words it had: five chunks about e-books, the devices they open
on, audiobooks, reading in the app. None of them is the refund rule, because the question never said
it was about returning anything. The same question written out in full:

```
ana@vm:~/rag$ python show.py vector "How long do I have to return an e-book?"
1    0.794  Returns and refunds policy > E-books and audiobooks  | An e-book can be refunded within 14 days of purc
2    0.793  E-books and audiobooks > Refunds for e-books  | An e-book can be refunded within 14 days of purc
3    0.770  Returns policy > Returning a book  | You may return a printed book within 14 days of 
4    0.739  Returns policy > Damaged books  | If a book arrives damaged, send it back within 1
5    0.736  Returns and refunds policy > The return window  | You have 30 days from delivery to return a print
```

**The two chunks with the e-book refund rule come first, at 0.794 and 0.793.** The rewrite here was
written by the course, by hand. In a real system it is a language model's job: given the conversation
so far and the last message, write the message as a question that stands on its own. It is one of the
cheapest model calls in a pipeline, and lesson 13 builds the conversation history it needs.

## Other rewrites

- **Expanding vocabulary.** Customers say *money back* and documents say *refund*. A rewrite can add
  the document's words, or a list of synonyms kept by the team can.
- **Splitting a compound question.** *Can I return a signed copy and how long does the refund take?* is
  two questions with two answers in two sections. Searching for each separately and merging the
  results finds both; searching once finds whichever dominates the vector.
- **Several phrasings at once.** Some pipelines generate three or four versions of the question, search
  for each, and fuse the lists with the same reciprocal rank fusion as the last section. It costs a
  search per phrasing and helps most when questions are short and vague.
- **A hypothetical answer.** The method called HyDE has a model write a plausible answer, without
  sources, and searches with that instead of the question, because an answer looks more like a chunk
  than a question does. It was not run here; the risk is plain from lesson 1, which showed what
  a model writes without sources, a library's loan rules for a bookshop's question.

Each of these is measurable with the same test set as everything else in this lesson, and none of them
should go into a pipeline unmeasured: a rewrite that helps vague questions can hurt precise ones, by
replacing the user's exact identifier with a paraphrase.
