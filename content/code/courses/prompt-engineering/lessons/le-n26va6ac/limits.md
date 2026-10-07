---
title: What a vote cannot fix
version: 2
---

Self-consistency is easy to describe and easy to oversell. **It turns N samples into one answer at
N times the cost, and only for questions whose answers can be counted.** Four limits decide when it
is worth it.

## It multiplies the cost

Every sample is a full chain, and every chain is output tokens. The seven chains:

```
ana@lab:~/pe$ tok count chains/*.txt
tokens  words  chars  file
   230    166    767  chains/s1.txt
   288    209    991  chains/s2.txt
   167    119    563  chains/s3.txt
   222    159    754  chains/s4.txt
   201    142    659  chains/s5.txt
   228    158    696  chains/s6.txt
   203    147    651  chains/s7.txt
```

Together they are 1,539 output tokens for one answer, as `tok` counts them, against a single chain's 167 to 288, and the
prompt is sent seven times as well (or once, if the API accepts a sample count and bills the input
once; check its documentation). **Seven samples cost about seven times as much as one**, and a vote
of twenty costs twenty. The samples can run in parallel, so the wait need not grow the same way,
but the bill does. Self-consistency belongs on questions where a wrong answer costs more than the
extra calls.

## It needs answers that can be compared

The vote counted `54`, `66`, `72` and `78`, because a number is the same string whoever wrote the
chain.
A label works the same way: `yes` or `no`, `refund` or `replace`, one of five categories. **Free
text does not.** Five summaries of a customer's complaint are five different paragraphs, and no
two will match character for character, so every "vote" is a tie of ones.

Even with numbers, the answers have to be normalised before they are counted. `54`, `R$ 54` and
`54.00` are one answer to a person and three to a program that compares strings. Fix the format in
the prompt ("Answer: followed by the number only") and normalise what comes back before counting.

## It can tie

With three samples and three different answers, there is no majority at all:

```
ana@lab:~/pe$ vote chains/s1.txt chains/s2.txt chains/s6.txt
chains/s1.txt    72
chains/s2.txt    54
chains/s6.txt    78
votes: 72 x1, 54 x1, 78 x1
no majority: a tie between 72 and 54 and 78
```

A program has to decide in advance what a tie means. Picking one of the tied answers at random
hides the problem. **A tie is a measurement: the question is hard for this prompt**, and the useful
responses are more samples, a better prompt, or a person.

## A majority can be wrong

Voting works when wrong chains scatter. When most chains make **the same** mistake, they agree with
each other, and the vote counts that agreement as confidence. The café order above already showed
it, with 66 winning. Lesson 25's holiday question shows it more starkly: on a Wednesday that is a
public holiday, can the kitchen take a hot food order at 11:45?

```
ana@lab:~/pe$ cat prompts/holiday-vote.txt
Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday. On Sundays it opens at 08:00 and closes at 12:00. The kitchen stops taking hot food orders 30 minutes before closing. On public holidays the café follows the Sunday hours.

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Think it through, then end with one line: The answer is yes, or The answer is no.
ana@lab:~/pe$ mkdir -p holiday; for i in 1 2 3 4 5; do ask - --temperature 0.8 --seed $i --plain < prompts/holiday-vote.txt > holiday/h$i.txt; done
ana@lab:~/pe$ vote holiday/*.txt
holiday/h1.txt   yes
holiday/h2.txt   yes
holiday/h3.txt   yes
holiday/h4.txt   yes
holiday/h5.txt   (no answer line: no vote)
votes: yes x4
majority: yes (4 of 4 answers, 5 files)
ana@lab:~/pe$ tail -1 holiday/h5.txt
Since today is Wednesday, which is a public holiday, Café Aurora follows the Sunday hours, which means it opens at 08:00 and closes at 12:00. The kitchen stops taking hot food orders 30 minutes before closing, which would be 10:30 on a regular Wednesday. However, since it's a public holiday, the kitchen closes at 12:00, making the 30 minutes before closing 11:30. Since the customer ordered at 11:45, which is after 11:30, the kitchen is no longer taking hot food orders.
```

Four votes for `yes`, unanimous among the replies that had an answer line, and the handbook says
`no`. The fifth sample is the only one that reasoned its way to 11:30 and the right conclusion,
and it never wrote the answer line, so it cast no vote. **The vote was as confident as a vote can
be, and wrong.** The likeliest cause is the pull lesson 25 described, the word *Wednesday* towards the weekday hours. If every `yes` shares it, more samples of the same prompt would most likely make the
wrong majority firmer, not weaker. The fix is in the prompt: step back to the rules first (lesson
25), and then vote among chains that start from them.

The same is true of `toylm`'s seven samples in the previous reading section. `six` won five to
two, and on a Sunday it is the wrong answer: the café closes at noon. **A vote measures agreement
between samples, not agreement with the facts.**

## Where it sits among the techniques

Lesson 26's chain of thought follows one path. Self-consistency follows several independent paths
to the end and compares only where they arrive. Lesson 28 goes a step further: it compares partial
paths as they go, keeps the promising ones and drops the rest before they are finished.
