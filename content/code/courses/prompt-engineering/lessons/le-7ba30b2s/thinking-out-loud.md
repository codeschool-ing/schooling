---
title: Asking for the steps before the answer
version: 1
---

The usual picture is that a model works the answer out somewhere inside and then reports it, so
asking it to "show its working" only adds words for your benefit. That is not how it produces
text. **The model has no scratch space apart from the text it writes.** Asking for the steps
before the answer gives it one, and the answer that comes after them is predicted from those
steps. That is chain-of-thought prompting.

## One order, two ways

A table at Café Aurora orders three flat whites at R$ 12 each and two slices of cake at R$ 15
each. They pay with a loyalty card that already has 9 stamps, and the handbook says the tenth
coffee is free. Asked for the amount and nothing else, a model has to put the number first. The
course wrote this reply as an illustration of what can come back:

```localised
R$ 66
```

Asked instead to "work it out step by step, then write the result on a last line that starts with
Answer:", the reply begins with the steps. This one is also the course's illustration, not a
capture:

```localised
Three flat whites at R$ 12 each.
The card already has 9 stamps, so the first coffee of this order is the
tenth, and it is free.
That leaves 2 coffees to pay for: 2 x 12 = R$ 24.
Two slices of cake at R$ 15 each: 2 x 15 = R$ 30.
Total: 24 + 30 = R$ 54.
Answer: 54
```

Neither reply's arithmetic needs to be taken on trust. Python checks the full price, the price
with one coffee free, and the worked example used further down:

```
ana@lab:~/pe$ python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"
66 54 29
```

**66 is not a random mistake: it is the bill with every coffee paid for**, the obvious reading of
the order. The loyalty rule needs one step in between, and the direct reply had nowhere to put it.

## Why writing the steps helps a next-token predictor

Lesson 1 showed the loop: the model scores the next token from the text so far, one is picked, and
it joins the text. In the direct reply the first token of the answer is chosen with nothing in
front of it but the question. In the chain, by the time the model reaches `Answer:`, the text
already contains "the first coffee of this order is the tenth, and it is free" and "Total: 24 + 30
= R$ 54". **Each step it wrote is now text the next tokens are conditioned on**, and the likely
continuation of `Total: 24 + 30 = R$` is `54`.

That is the whole mechanism, and it explains where chain of thought helps: problems whose answer
needs intermediate results, such as arithmetic over several items, a rule applied before a sum, or
two facts combined. A one-step question ("what does a flat white cost?") has no intermediate
result to write, and gains nothing from being asked to reason.

## Few-shot and zero-shot chains

There are two ways to get the steps.

**Few-shot chain of thought shows a worked example in the prompt**, with its steps written out, and
then asks the new question. The model continues the pattern it was shown, as in lesson 21:

```
Q: A customer orders 2 espressos at R$ 9 each and 1 cinnamon bun at R$ 11. Their loyalty card has 3 stamps; the tenth coffee is free. How much do they pay?
A: The card has 3 stamps, so these espressos are the 4th and 5th coffees. Neither is the tenth, so both are paid: 2 x 9 = 18. The bun is 11. Total: 18 + 11 = 29.
Answer: 29

Q: A table orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. Their loyalty card has 9 stamps; the tenth coffee is free. How much do they pay?
A:
```

The example teaches the format of the steps, how far to break the problem down, and the `Answer:`
line at the end. The 29 in it is checked by the same Python line as the order above.

**Zero-shot chain of thought adds only an instruction**, with no example: "think step by step" or,
better, a sentence that also fixes the last line, as in the second request above. It is cheaper to
write and to send, and it leaves the model to choose how to lay the steps out. Lesson 20 covered
zero-shot prompting in general; this is the same idea with one sentence that asks for the working.

A few-shot chain is worth the extra tokens when you need a particular layout of steps, or when the
model's own breakdown keeps skipping the step that matters. Otherwise the instruction is usually
enough to start with.
