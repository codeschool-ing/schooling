---
title: Equivalence partitions
version: 1
---

**The first instinct with a field is to try a lot of values in it**, and to feel more thorough with
each one. R4 lets somebody book 1 to 6 tickets; a tester who books 1, then 2, then 3, then 4 and
then 5 has run five cases and asked one question five times. If boxoffice books three tickets
correctly, there is very little reason to think it books four any differently: the requirement
treats them the same, and so, almost certainly, does the code.

That observation is the whole technique. **An equivalence partition is a set of inputs the
requirement says should be handled the same way**, and one value taken from it stands for all the
others. Testing a second value from the same partition costs a case and buys almost nothing; testing
a value from a partition nobody has tried yet is a new question. The aim is to cover every
partition at least once, with as few cases as that takes.

## The requirement draws the lines

The partitions come from what the requirement says, not from what the program happens to do. That
is what makes this a black-box technique, in the sense `qa-fundamentals` gave the word: you can
draw them before a line of code exists, and you draw them the same way whether or not you can read
the code.

Take R2's two lengths. "A name of 1 to 40 characters" splits every possible name into three:

- **empty**, no characters at all, which the requirement refuses;
- **1 to 40 characters**, which it accepts;
- **41 characters or more**, which it refuses.

"A password of 8 to 64 characters" does the same, with different numbers: 0 to 7 refused, 8 to 64
accepted, 65 or more refused. The middle partition of each is **valid**, the input the program
should accept and act on; the two outer ones are **invalid**, the input it should turn away with a
sentence saying what is wrong (R7). Both kinds are partitions, and both need a case. A tester who
only feeds a form what it asks for has tested half of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-partitions\" aria-label=\"Three bars, one per field, each split into three partitions. Name length: empty, refused; 1 to 40, accepted; 41 or more, refused. Password length: 0 to 7, refused; 8 to 64, accepted; 65 or more, refused. Tickets per order: 0 or fewer, refused; 1 to 6, accepted; 7 or more, refused; and beside that bar a dashed fourth partition, not a whole number, refused with a sentence.\"><text x=\"20.0\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">name length</text><text x=\"20.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R2</text><rect x=\"160.0\" y=\"22.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">empty</text><text x=\"210.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><rect x=\"264.0\" y=\"22.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 to 40</text><text x=\"357.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">accepted</text><rect x=\"454.0\" y=\"22.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">41 or more</text><text x=\"504.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><text x=\"20.0\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">password length</text><text x=\"20.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R2</text><rect x=\"160.0\" y=\"92.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0 to 7</text><text x=\"210.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><rect x=\"264.0\" y=\"92.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8 to 64</text><text x=\"357.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">accepted</text><rect x=\"454.0\" y=\"92.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">65 or more</text><text x=\"504.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><text x=\"20.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tickets per order</text><text x=\"20.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R4</text><rect x=\"160.0\" y=\"162.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0 or fewer</text><text x=\"210.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><rect x=\"264.0\" y=\"162.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 to 6</text><text x=\"357.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">accepted</text><rect x=\"454.0\" y=\"162.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7 or more</text><text x=\"504.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><rect x=\"570.0\" y=\"162.0\" width=\"150.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"645.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">not a whole number</text><text x=\"645.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused, with a sentence</text></svg>", "caption": "The partitions of R2 and R4, as the requirements draw them. Each bar has one valid partition between two invalid ones, and the quantity has a fourth that is not on the number line at all. The widths are not to scale."}
```

Not every partition is a range of numbers. R2's e-mail address has to be one "no other account
uses", which splits addresses into two: an address nobody has, and an address an account already
has. Neither is a length. The seeded account, `member@example.org`, is a ready-made member of the
second partition, and signing up with it is the case that tests it.

## One value from each

For each partition, pick one **representative value**, and pick it from the middle rather than the
edge: the edges get cases of their own in section 03 of this lesson, and a representative's job is
to say how the partition as a whole behaves. For R2:

| field | partition | kind | representative |
|---|---|---|---|
| name | empty | invalid | no name at all |
| name | 1 to 40 characters | valid | `Ana Lima`, 8 characters |
| name | 41 or more | invalid | a name of 60 characters |
| password | 0 to 7 characters | invalid | `abc`, 3 characters |
| password | 8 to 64 characters | valid | a password of 20 characters |
| password | 65 or more | invalid | a password of 100 characters |
| e-mail | not used by any account | valid | `new@example.org` |
| e-mail | used by an account | invalid | `member@example.org` |

Eight partitions, but not eight cases. **Valid partitions can share a case**: one sign-up with
`Ana Lima`, a 20-character password and `new@example.org` puts a value in all three valid
partitions at once, and if it creates the account, all three behaved. Invalid partitions cannot
share, and section 05 of this lesson shows why with a capture. So R2 needs one valid case and five
invalid ones, six in all, where trying names one after another has no natural end.

## Where partitioning goes wrong

**Partitions are a claim about the program, and the claim can be false.** The technique assumes
that every value in a partition is handled alike, and it is right as often as the code follows the
requirement. Where the code splits a partition the requirement did not, say it treats names over
30 characters differently because that is the width of a column in some database, one
representative from the middle will not notice. The defence is the next technique, which goes to
the places where lines are drawn, and the habit of asking the developer whether any limit exists
that the requirement does not mention.

The other way to go wrong is to miss a partition altogether, and the usual one missed is the input
the form does not expect. A name field is drawn as a box for letters; nothing stops somebody typing
digits into it, or pasting 3,000 characters, or nothing. Section 05 of this lesson is about that
partition, in the field where boxoffice gets it wrong.
