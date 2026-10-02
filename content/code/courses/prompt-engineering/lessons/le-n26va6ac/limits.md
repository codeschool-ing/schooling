---
title: What a vote cannot fix
version: 1
---

Self-consistency is easy to describe and easy to oversell. **It turns N samples into one answer at
N times the cost, and only for questions whose answers can be counted.** Four limits decide when it
is worth it.

## It multiplies the cost

Every sample is a full chain, and every chain is output tokens. The five illustrated chains:

```
ana@lab:~/pe$ tok count chains/*.txt
tokens  words  chars  file
    59     40    158  chains/s1.txt
    43     26    110  chains/s2.txt
    34     23     90  chains/s3.txt
    35     26    138  chains/s4.txt
    38     29    142  chains/s5.txt
```

Together they are 209 output tokens for one answer, against a single chain's 34 to 59, and the
prompt is sent five times as well (or once, if the API accepts a sample count and bills the input
once; check its documentation). **Five samples cost about five times as much as one**, and a vote
of twenty costs twenty. The samples can run in parallel, so the wait need not grow the same way,
but the bill does. Self-consistency belongs on questions where a wrong answer costs more than four
extra calls.

## It needs answers that can be compared

The vote counted `54`, `66` and `42`, because a number is the same string whoever wrote the chain.
A label works the same way: `yes` or `no`, `refund` or `replace`, one of five categories. **Free
text does not.** Five summaries of a customer's complaint are five different paragraphs, and no
two will match character for character, so every "vote" is a tie of ones.

Even with numbers, the answers have to be normalised before they are counted. `54`, `R$ 54` and
`54.00` are one answer to a person and three to a program that compares strings. Fix the format in
the prompt ("Answer: followed by the number only") and normalise what comes back before counting.

## It can tie

With three samples and three different answers, there is no majority at all:

```
ana@lab:~/pe$ vote chains/s1.txt chains/s3.txt chains/s5.txt
chains/s1.txt 54
chains/s3.txt 66
chains/s5.txt 42
votes: 54 x1, 66 x1, 42 x1
no majority: a tie between 54 and 66 and 42
```

A program has to decide in advance what a tie means. Picking one of the tied answers at random
hides the problem. **A tie is a measurement: the question is hard for this prompt**, and the useful
responses are more samples, a better prompt, or a person.

## A majority can be wrong

Voting works when wrong chains scatter. When most chains make **the same** mistake, they agree with
each other, and the vote counts that agreement as confidence. Lesson 25's holiday question is the
case: on a Wednesday that is a public holiday, can the kitchen take a hot food order at 11:45? Again
the five chains were written by the course as an illustration:

```
ana@lab:~/pe$ head holiday/*.txt
==> holiday/h1.txt <==
It is Wednesday, and on weekdays the café closes at 18:00, so the kitchen takes hot food until 17:30. 11:45 is before that. The answer is yes.

==> holiday/h2.txt <==
Wednesday hours are 07:00 to 18:00. The kitchen stops 30 minutes before closing, at 17:30. The answer is yes.

==> holiday/h3.txt <==
A public holiday follows the Sunday hours: closing at 12:00, so hot food stops at 11:30. 11:45 is too late. The answer is no.

==> holiday/h4.txt <==
The café is open on Wednesdays until 18:00 and the order is at 11:45, well inside the hours. The answer is yes.

==> holiday/h5.txt <==
Holidays use Sunday hours, so the café closes at noon and the last hot food order is 11:30. The answer is no.
ana@lab:~/pe$ vote holiday/*.txt
holiday/h1.txt yes
holiday/h2.txt yes
holiday/h3.txt no
holiday/h4.txt yes
holiday/h5.txt no
votes: yes x3, no x2
majority: yes (3 of 5)
```

The majority is `yes`, and the handbook says `no`. The three wrong chains share one cause: the word
*Wednesday* pulls each of them to the weekday line, the pull lesson 25 described. **Sampling more
of the same prompt repeats the same pull**, so more samples would most likely make the wrong
majority firmer, not weaker. The fix is in the prompt: step back to the rules first (lesson 25),
and then vote among chains that start from them.

The same is true of `toylm`'s seven samples in the previous reading section. `six` won five to two, and on a Sunday it is
the wrong answer: the café closes at noon. **A vote measures agreement between samples, not
agreement with the facts.**

## Where it sits among the techniques

Lesson 26's chain of thought follows one path. Self-consistency follows several independent paths
to the end and compares only where they arrive. Lesson 28 goes a step further: it compares partial
paths as they go, keeps the promising ones and drops the rest before they are finished.
