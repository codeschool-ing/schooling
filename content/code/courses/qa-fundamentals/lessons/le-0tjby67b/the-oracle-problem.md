---
title: How do you know the answer is right?
version: 1
---

**A test oracle is whatever a tester uses to decide whether a result is right.** Running a test produces a result:
a price, a message, a screen. The result says nothing on its own. Something has to say what it *should* have been,
and that something is the oracle. William Howden gave it the name in 1978, borrowing the word for a source of answers
the asker cannot work out alone.

Every test in this course has had one, usually without anyone pointing at it:

| test | the result | the oracle |
|---|---|---|
| lesson 1: `python tickets.py 60 no thu 20:00` | R$ 36,00 | Joana's rule, read with the statute's meaning of *over 60* |
| lesson 4: the Sunday 9:30 order | R$ 108,00 | the price at the counter, R$ 84,00 |
| lesson 8: the order of seven tickets | stored with a total of 0 | the rule's fourth sentence: an order holds 1 to 6 tickets |
| lesson 17: the outline | `R$ 9,00` for a student on Wednesday | the green cards Joana agreed |

## The oracle problem

For a price rule with five sentences, the oracle is easy to find: work the price out by hand from the rule. For most
real software it is not. What should the seat map look like when two people book the same seat at the same moment?
How fast is fast enough? What is the right recommendation for a customer who has seen every film this month? Often
nobody has written the answer down, and for some questions nobody can.

This is called **the oracle problem**: generating inputs is easy, and a computer can do it all day; knowing what the
right output would have been is hard, and it does not scale. A test without an oracle is not a test. It is a program
being run, with a person hoping they would notice if something were wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 220\" role=\"img\" data-fig=\"l19-oracle\" aria-label=\"A test drawn as a flow. An input, age 60 at a Thursday 20:00 session, goes into the program, which gives a result, R$ 36,00. Separately, an oracle, the rule, the counter, the law or an example, says what the result should be. The two are compared, and the verdict is: wrong, according to the statute, which says R$ 18,00.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"38.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">input</text><text x=\"70.0\" y=\"51.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">60, thu 20:00</text><path d=\"M131.0 45.0 L169.0 45.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"20.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the program</text><path d=\"M301.0 45.0 L339.0 45.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"340.0\" y=\"20.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"38.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">result</text><text x=\"400.0\" y=\"51.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">R$ 36,00</text><rect x=\"340.0\" y=\"140.0\" width=\"120.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"160.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">oracle</text><text x=\"400.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the rule, the counter,</text><text x=\"400.0\" y=\"185.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the law, an example</text><path d=\"M461 45 C 500 45, 500 85, 520 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M461 173 C 500 173, 500 135, 520 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"495.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">compare</text><rect x=\"522.0\" y=\"78.0\" width=\"110.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"577.0\" y=\"97.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">verdict</text><text x=\"577.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">wrong, according to</text><text x=\"577.0\" y=\"122.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the statute: R$ 18,00</text></svg>", "caption": "Running the program gives a result. Only the oracle turns it into a verdict, and the verdict names it."}
```

## Why it matters to a tester

Three habits follow from taking oracles seriously.

- **Know which oracle you are using.** When Lia says a price is wrong, she says *wrong according to what*: the rule,
  the counter, the agreed example, the law. A defect report that names its oracle can be argued with; one that only
  says "wrong" cannot.
- **Look for an oracle before the test.** A test planned without one produces a result nobody can judge. In lesson 6
  every case had its expected price written beside it before anything ran; that column was the oracle.
- **Have more than one.** Every oracle can be wrong, and the next sections show how. A result two independent oracles
  agree on is worth more than one that only one of them checked.

The rest of this lesson is about the kinds of oracle available when the expected answer is not simply written down,
and about one kind that can find defects without knowing the right answer at all.
