---
title: Sampling several chains and taking a vote
version: 1
---

Lesson 26 ended on a chain that read well and was wrong. The tempting fix is to make the one
chain more careful: a better instruction, a longer example. **Self-consistency takes a different
route: it asks for several chains of thought to the same question and keeps the final answer that
most of them reach.** It does not try to make any single chain right. It relies on wrong chains
going wrong in different ways, while right chains, whatever their wording, arrive at the same
number.

## Why the samples have to differ

A vote among copies is no vote. At temperature 0 a model takes the top-scoring token at every
step (lesson 13), so the same prompt gives the same text each time. `toylm` shows it with five
seeds:

```
ana@lab:~/pe$ toylm generate "the café closes at" --temperature 0 --samples 5
[seed 1] six.
[seed 2] six.
[seed 3] six.
[seed 4] six.
[seed 5] six.
```

Five identical answers say nothing that one did not. **The samples have to be drawn at a
temperature above 0**, so that each one can take a different path. Lesson 1's `--samples` does
exactly that at `toylm`'s default temperature:

```
ana@lab:~/pe$ toylm generate "the café closes at" --samples 7
[seed 1] six.
[seed 2] noon on sunday.
[seed 3] six.
[seed 4] six.
[seed 5] six.
[seed 6] noon on sunday.
[seed 7] six.
```

That is already a small vote, counted by eye: `six` five times, `noon on sunday` twice. Both are
true in the café's corpus, and the next reading section comes back to what that means for a vote. A large model sampled the same
way gives chains that differ in wording, in the order of the steps, and sometimes in a step that
goes wrong.

## Five chains for the café order

The question is lesson 26's: three flat whites at R$ 12, two slices of cake at R$ 15, and a
loyalty card already on 9 stamps. The five chains below were **written by the course as an
illustration** of five samples a model might return at a temperature above 0. Ana saved each in
its own file:

```
ana@lab:~/pe$ head chains/*.txt
==> chains/s1.txt <==
The card has 9 stamps, so the first flat white is the tenth coffee and free. Two are paid: 2 x 12 = 24. Cake: 2 x 15 = 30. 24 + 30 = 54, so the answer is 54.

==> chains/s2.txt <==
Coffees: 3 x 12 = 36. One of them is the tenth stamp, so take off 12: 24. Add the cake, 30. The answer is 54.

==> chains/s3.txt <==
Three flat whites at 12 is 36 and two slices at 15 is 30. 36 + 30 = 66. The answer is 66.

==> chains/s4.txt <==
Nine stamps plus this order: the next coffee completes the card and is free. Paid: two coffees (24) and two cakes (30). The answer is 54.

==> chains/s5.txt <==
The ninth stamp means the next coffee is free, and the one after starts a new free card. One coffee paid, 12, plus cake 30. The answer is 42.
```

Three chains reach 54 by three different routes: one subtracts the free coffee, one counts only
the paid ones, one reasons about the card filling up. The two wrong chains are wrong differently:
`s3` forgets the card, `s5` invents a second free coffee.

`vote` is a real program, printed in `lab.sh`. It takes the last "answer is ..." in each file and
counts them:

```
ana@lab:~/pe$ vote chains/*.txt
chains/s1.txt 54
chains/s2.txt 54
chains/s3.txt 66
chains/s4.txt 54
chains/s5.txt 42
votes: 54 x3, 66 x1, 42 x1
majority: 54 (3 of 5)
```

**Only the final answers are compared; the reasoning is thrown away.** That is what makes the vote
possible: five paragraphs worded differently cannot be counted, five numbers can. It is also why
each chain needs a fixed answer phrase, the same habit as lesson 26's `Answer:` line, so a program
can find what to count.

## The procedure

1. Write one chain-of-thought prompt that ends in a fixed answer line.
2. Send it N times at a temperature above 0, or once with a parameter that asks for N samples, if
   the API has one.
3. Extract the final answer from each reply, and treat a reply with none as no vote.
4. Take the most common answer.

The share the winner got is useful too. **3 of 5 is a weaker result than 5 of 5**, and a program
can act on that: accept a unanimous vote, and send a split one to a person or to a second round of
samples.
