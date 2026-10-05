---
title: Measuring the endpoint on your own messages
version: 1
---

A vendor publishes how well its classifier does on its own test sets. Those numbers describe
messages the vendor collected, in the languages it chose, labelled by its rules. **The number that
decides anything at Tarefa is the one measured on Tarefa's messages**, and the only way to get it is
a set of real messages with a label a person gave each one, run through the endpoint.

`data/forum.jsonl` is that set for the lab: sixty forum messages, each labelled with the categories
a person would put it in, or none. **The messages and the labels were written by the course.** A
real set would be sampled from what users actually post, and labelled by two people working apart,
so that the disagreement between them is measured too; the course `prompt-reliability` measures that
agreement with a statistic built for it.

```
ana@lab:~/guard$ head -3 data/forum.jsonl
{"id": "m01", "lang": "en", "labels": ["harassment"], "text": "You are an idiot and everybody here knows it"}
{"id": "m02", "lang": "en", "labels": ["harassment"], "text": "Nobody wants your useless designs, quit already"}
{"id": "m03", "lang": "en", "labels": ["harassment"], "text": "What a pathetic excuse for a developer"}
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --threshold 0.5 --show
category harassment: 15 of 60 messages labelled harassment by a person
threshold 0.50
              labelled yes  labelled no
flagged                11            4
not flagged             4           41
precision 0.73   recall 0.73
  recall, messages in en: 11 of 13
  recall, messages in pt: 0 of 2
  MISSED         m08 0.00  u r an id1ot
  MISSED         m10 0.00  Seu idiota, ninguém te contrata
  MISSED         m11 0.00  Vai catar coquinho, incompetente
  MISSED         m15 0.00  Such a brilliant idea, genius. Really.
  FALSE POSITIVE m32 0.90  He called me an idiot in the chat, can a moderator look?
  FALSE POSITIVE m33 0.80  Is 'stupid' too strong for a band name in a logo brief?
  FALSE POSITIVE m34 0.60  My client said my work was garbage. How do I answer politely?
  FALSE POSITIVE m57 0.60  What a clown I was, I forgot the attachment
```

## Two numbers, and what each one costs somebody

The four cells are the whole result. Precision and recall are two ways of reading them:

- **Precision** is how many of the flagged messages really were harassment: 11 of 15, 0.73. The 4
  others are people whose messages were stopped for nothing.
- **Recall** is how many of the harassing messages were flagged: 11 of 15, 0.73. The 4 missed are
  messages that reached their target.

That both are 0.73 here is a coincidence of this set. They answer different questions, and they
move in opposite directions when the threshold moves, which is the next section.

## Reading the mistakes

The totals say how often; `--show` says what, and the mistakes have patterns that a total hides.

The four **missed** messages are an insult spelt with a digit, `id1ot`, a piece of sarcasm, and two
insults in Portuguese. The per-language lines put a number on the last of those: recall is 11 of 13
in English and **0 of 2 in Portuguese**. The stand-in knows no Portuguese at all, so that is its
extreme case. Real classifiers trained mostly on English text usually show a milder version of the
same gap. At a Brazilian company, a classifier evaluated only on English messages has never really
been evaluated.

The four **false positives** are more uncomfortable. `m32` is somebody reporting that they were called an idiot, and `m34` is somebody asking how to
answer a client who called their work garbage. `m33` asks about a word for a band's logo, and `m57`
is somebody calling themselves a clown. None of them is
harassment, and two are its targets asking what to do. A filter that blocks
reports of harassment teaches people that reporting gets them blocked.

Sixty messages are enough to see these patterns and too few to trust a rate to the second decimal:
two Portuguese messages say nothing precise about Portuguese recall. The set is a fixture for
learning the method. A real one grows with every message a moderator reviews, because each review is
a new label.
