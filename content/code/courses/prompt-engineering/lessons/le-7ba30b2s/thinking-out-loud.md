---
title: Asking for the steps before the answer
version: 2
---

The usual picture is that a model works the answer out somewhere inside and then reports it, so
asking it to "show its working" only adds words for your benefit. That is not how it produces
text. **The model has no scratch space apart from the text it writes.** Asking for the steps
before the answer gives it one, and the answer that comes after them is predicted from those
steps. That is chain-of-thought prompting.

## One order, two ways

A table at Café Aurora orders three flat whites at R$ 12 each and two slices of cake at R$ 15
each. They pay with a loyalty card that already has 9 stamps, and the handbook says the tenth
coffee is free. Asked for the amount and nothing else, a model has to put the number first:

```
ana@lab:~/pe$ cat order-direct.txt
A table at Café Aurora orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. They pay with a loyalty card that already has 9 stamps, and the tenth coffee is free. How much do they pay? Reply with the amount only.
ana@lab:~/pe$ ask - --temperature 0 --plain < order-direct.txt | tee direct.txt
R$ 39
```

Asked instead to "work it out step by step, then write the result on a last line that starts with
Answer:", which is the same prompt with that sentence in place of the last one, the reply begins
with the steps:

```
ana@lab:~/pe$ tail -c 80 order-chain.txt
out step by step, then write the result on a last line that starts with Answer:
ana@lab:~/pe$ ask - --temperature 0 --plain < order-chain.txt | tee chain.txt
To calculate the total cost, we need to first calculate the cost of the flat whites and the cake.

Cost of flat whites: 3 x R$ 12 = R$ 36
Cost of cake: 2 x R$ 15 = R$ 30

Total cost: R$ 36 + R$ 30 = R$ 66

Since the customer has 9 stamps on their loyalty card, they have already earned 9 free coffees. However, they are ordering 3 flat whites, which means they will only get 2 free coffees (since the 10th coffee is free). So, they will pay for 1 flat white.

Cost of 1 flat white: R$ 12

Total cost: R$ 66 - R$ 12 = R$ 54

Answer: R$ 54
```

Neither reply's arithmetic needs to be taken on trust. Python checks the full price, the price with
one coffee free, and the worked example used further down:

```
ana@lab:~/pe$ python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"
66 54 29
```

The direct reply is **R$ 39, which is not any reading of the order**: not the full bill, not the
bill with a free coffee. The chain got 54, the right answer, and it is worth reading how. The first
three lines are right: 36, 30, 66. The paragraph after them is wrong in every clause, "already
earned 9 free coffees", "only get 2 free coffees", "pay for 1 flat white", and then the next line
subtracts one coffee from 66, which is exactly the right correction. **The answer is right and the
reason given for it is not.** That is worth holding on to; the next reading section comes back to
it.

## Why writing the steps helps a next-token predictor

Lesson 1 showed the loop: the model scores the next token from the text so far, one is picked, and
it joins the text. In the direct reply the first token of the answer is chosen with nothing in
front of it but the question. In the chain, by the time the model reaches `Answer:`, the text
already contains "Total cost: R$ 66 - R$ 12 = R$ 54". **Each step it wrote is now text the next
tokens are conditioned on**, and the likely continuation of a text that has just said 54 is 54.

That is the whole mechanism, and it explains where chain of thought helps: problems whose answer
needs intermediate results, such as arithmetic over several items, a rule applied before a sum, or
two facts combined. A one-step question ("what does a flat white cost?") has no intermediate
result to write, and gains nothing from being asked to reason.

## Few-shot and zero-shot chains

There are two ways to get the steps.

**Few-shot chain of thought shows a worked example in the prompt**, with its steps written out, and
then asks the new question. The model continues the pattern it was shown, as in lesson 21:

```
ana@lab:~/pe$ cat order-few.txt
Q: A customer orders 2 espressos at R$ 9 each and 1 cinnamon bun at R$ 11. Their loyalty card has 3 stamps; the tenth coffee is free. How much do they pay?
A: The card has 3 stamps, so these espressos are the 4th and 5th coffees. Neither is the tenth, so both are paid: 2 x 9 = 18. The bun is 11. Total: 18 + 11 = 29.
Answer: 29

Q: A table orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. Their loyalty card has 9 stamps; the tenth coffee is free. How much do they pay?
A:
ana@lab:~/pe$ ask - --temperature 0 --plain < order-few.txt | tee few.txt
To solve this problem, we need to determine how many coffees the table has ordered and how many stamps are left on their loyalty card.

The table orders 3 flat whites at R$ 12 each, which is a total of 3 x 12 = 36. They also order 2 slices of cake, which is a total of 2 x 15 = 30. The total amount they pay is 36 + 30 = 66.

Since the loyalty card has 9 stamps, and the tenth coffee is free, we need to determine how many coffees they have ordered. The tenth coffee is free, so we can assume that the table has ordered at least 9 coffees. Since they have ordered 3 flat whites, they must have ordered at least 9 flat whites to reach the 9th stamp. However, they have also ordered 2 slices of cake, which means they have ordered a total of 3 flat whites + 2 slices of cake = 5 coffees.

Since the table has ordered 5 coffees, and the loyalty card has 9 stamps, they have 4 stamps left. This means that the 6th, 7th, 8th, and 9th coffees are free. The 10th coffee is also free, so the table only pays for the 5 coffees they ordered.

The total amount they pay is 66 - 4 (free coffees) = 62.
```

The example was meant to teach the format of the steps, how far to break the problem down, and the
`Answer:` line at the end; the 29 in it is checked by the same Python line above. This model took
none of the three. The reply is longer than the example, counts the two slices of cake as coffees,
decides four coffees are free, and ends on 62, wrong, with no `Answer:` line. Lesson 21 measured
examples making this model worse at labelling, and this is the same lesson on a sum: **an example
is a request, and only the reply shows whether it was followed.**

**Zero-shot chain of thought adds only an instruction**, with no example: "think step by step" or,
better, a sentence that also fixes the last line, as in the second request above. It is cheaper to
write and to send, and it leaves the model to choose how to lay the steps out. Lesson 20 covered
zero-shot prompting in general; this is the same idea with one sentence that asks for the working.

A few-shot chain is worth the extra tokens when you need a particular layout of steps, or when the
model's own breakdown keeps skipping the step that matters, and when a test set shows the example
helps. Here the instruction alone did better.
