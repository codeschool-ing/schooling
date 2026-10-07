---
title: Reading the answer out, and what the chain costs
version: 2
---

A chain of thought is written for the model's benefit, and **a program that uses the reply needs
only the answer at the end of it**. Getting that answer out reliably, paying for the steps, and
not being taken in by them are the three things this section is about.

## A stated answer line

If the prompt says nothing about the end of the reply, the answer turns up wherever the model puts
it: "so they pay R$ 54", "the total comes to 54", "54 reais in all". A program reading that has to
guess which number in the paragraph is the result, and the chain itself is full of numbers. So the
instruction fixes the last line: "then write the result on a last line that starts with Answer:".
The previous section kept both chains, with `tee`, as `chain.txt` and `few.txt`. One command looks
for the answer in each:

```
ana@lab:~/pe$ grep "^Answer:" chain.txt few.txt || echo "no Answer: line"
chain.txt:Answer: R$ 54
ana@lab:~/pe$ tok count direct.txt chain.txt few.txt
tokens  words  chars  file
     5      2      6  direct.txt
   173    117    538  chain.txt
   293    224   1090  few.txt
```

**A fixed marker turns a paragraph into something a program can parse.** It found `R$ 54` in the
zero-shot chain, and nothing in the few-shot one, whose prompt only showed the line. If the line is
missing, treat the reply as failed rather than picking a number out of the text: the last number
in `few.txt` is 62, and it is wrong; lesson 19's rule about
validating output applies here too. Lesson 18's structured formats go further, with the reasoning
in one field and the answer in another.

## The steps are output, and output is paid

The three replies are the same order three ways, and the last command above counted them: 5 tokens
for the direct reply, 173 for the chain, 293 for the few-shot chain. **The right answer cost 173
output tokens against 5 for the wrong one**, almost thirty-five times as many, and the longest reply
was wrong anyway. Output tokens are usually priced higher than input tokens, and they are also the
slow part, since each one is a step of the loop from lesson 1. A chain on every request of a busy
service multiplies both the bill and the wait. Lesson 15's maximum-tokens limit matters more here
as well: a limit set for short answers can cut a chain off before it reaches its `Answer:` line,
and the reply then has no answer in it at all.

## Models that reason before they answer

At the time of writing (2026), several providers sell models trained to produce a chain of
reasoning on their own before the visible answer, often called reasoning or thinking models. With
those, "think step by step" adds little, because the steps happen anyway. Two things are worth
checking in the provider's documentation for the model you use: **whether the reasoning tokens are
billed as output even when you cannot see them**, and whether there is a setting for how much
reasoning to allow. The documentation and its date are the source; a list in a course would be out
of date within months.

## A chain can read well and be wrong

The steps look like an explanation, and that makes them persuasive. They are generated the same way
as everything else, and nothing checks them. The few-shot chain above is careful-sounding working
that counts cakes as coffees and lands on 62. A reader skimming it sees effort. **Check the answer,
and the facts the steps rely on, not the confidence of the prose.** Where the answer can be checked
by a program, as the Python line in the previous section did, check it that way.

A chain is also not a faithful record of how the answer was reached. The zero-shot chain shows it
from the other side: wrong reasons, then the right subtraction, then the right answer. A model can
write steps that do not lead to its answer, and tidy steps that lead to an answer it was going to
give anyway. Treat the chain as text that helps the answer
along and helps you spot a wrong turn, not as a proof. Lesson 27 uses this fact: if one chain can
go wrong, several chains can be compared.
