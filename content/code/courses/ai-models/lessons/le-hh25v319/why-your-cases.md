---
title: Why your own cases
version: 1
---

Every lesson so far has ended in the same place: quality has to be measured, and only on your own
work. This lesson is the measuring, and it is the part of the course that outlives every product
lessons 6 to 20 name. A model you choose this year will be retired; the cases you write to choose
it will choose its replacement.

## What a benchmark cannot tell you

A public benchmark answers "how does this model do on these questions". It is the right answer to
the wrong question, for three reasons that are each enough on their own:

- **The questions are not yours.** Lantern Books' e-mails are short, informal, sometimes in
  Portuguese, and about five things. No benchmark is made of them.
- **The labels are not yours.** Whether "can they leave it with a neighbour?" is about an order's
  status or about its address is a decision the shop makes. A model that disagrees with the shop is
  wrong for the shop, whatever a benchmark thinks.
- **The format is not yours.** Your program parses the reply. A benchmark that grades the meaning of
  an answer will pass a model that writes "Refund." where your code expects `refund`.

## What a case is

A **case** is three things written down together:

1. **an input**, exactly as the program will send it: here, a customer's e-mail;
2. **the expected output**, decided by a person who knows the task: the label, or the order number;
3. **how to judge a reply against it**: exact match, match after tidying, or a check a program can
   run.

Forty of them, run through each candidate, scored the same way, give a number per model that
means something to Lantern Books. That is an **evaluation**, and the rest of this lesson builds
one: the set (section 03), the scoring (04), the harness (05), and how to read what comes out
(06 to 10).

**The candidates are three small open models on your own machine.** `llama3.2:3b` is the course's
model; `llama3.2:1b` is the smaller one lesson 1 named for a weaker computer; and `qwen2.5:3b`, from
another family at the same size, is here because an evaluation needs candidates to compare and this
lesson alone uses it. Pull it before section 05 with `ollama pull qwen2.5:3b`; with less memory,
run the other two. They stand in for the hosted rows of lesson 4's matrix, which need keys, and
**their answers are real**: every score below is what they wrote, on the machine the course was
recorded on. With a key, the same harness runs on the hosted candidates unchanged.
