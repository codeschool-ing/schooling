---
title: Oracles can be wrong
version: 1
---

**Every oracle is a claim about what is right, and claims can be wrong.** A tester who treats an oracle as the truth
stops asking questions at exactly the moment a question is needed.

## How each kind fails

- **A specification can be wrong.** Joana's first sentence said *over 60*, and a program that followed it to the letter
  would have passed every check written from it and still broken the law. The oracle and the program agreed, and both
  were wrong.
- **An agreed example can be wrong.** If the three amigos had written *60 pays R$ 36,00* on a green card, the outline
  would have enforced the defect every day, automatically.
- **A reference can share the defect.** If the counter's printed price list had been made by running the same program,
  comparing against it would prove only that the program agrees with itself.
- **A human oracle can be wrong, or out of date.** Célia knows the prices she has always charged. On the first Wednesday
  after the rule changed, her expectation was the old rule.
- **A relation can be wrong.** *An earlier session never costs more* holds for this rule. A cinema that charged more
  for a special midnight screening would break it on purpose.

## When two oracles disagree

The most useful moment in testing is often not a failure but a disagreement: the rule says one thing, the example
another, the counter a third. Lesson 1 started with one, the code and the statute disagreeing at sixty.

A disagreement is not something a tester settles alone. It is information for the person who owns the decision:

1. **state both oracles and what each says**: *the outline says R$ 18,00, the poster at the door says Wednesday is half
   price on top of other discounts*;
2. **say what the product does**: *the program charges R$ 18,00*;
3. **ask who decides**: here, Joana. Her answer becomes a written example, and the oracle that was wrong gets
   corrected, the poster in this case.

## Naming the oracle in a defect report

Lesson 4's defect reports had *expected* and *observed*. The habit this lesson adds is a third line: **according to
what**. Compare:

> **expected:** R$ 18,00 · **observed:** R$ 9,00

> **expected:** R$ 18,00, by the rule's fifth sentence, *half price is the most any ticket is reduced* · **observed:**
> R$ 9,00

The second can be checked by anybody, argued with if the rule is read differently, and closed with a reference when it
is fixed. The first asks the reader to trust the tester's memory of the rule, which is exactly the kind of oracle this
section has been warning about.

## The tester as a collector of oracles

A tester's value lies less in running tests than in knowing **how to tell**. Every lesson in this course has added
oracles to Lia's collection: the rule, the counter, the statute, the agreed examples, the implicit wrongness of a
crash, the relations a rule implies, the people who use the product. A new tester has one or two. An experienced one
reaches for five, notices when they disagree, and knows that the disagreement is usually where the defect is.
