---
title: Small bases, and points against percent
version: 1
---

Two last shapes, both about the size of things. A percentage computed on a handful of cases moves
by enormous amounts for no reason at all, and a change between two percentages can be described in
two ways, one of them many times the size of the other. **Both are honest arithmetic, and both are how a report
says much more than its data can carry.**

## "Up 200%"

In January the new range of solar garden lamps had one complaint; in February, three. The report
said complaints about the range were up 200%, and somebody proposed pulling it from the shop. Put the
numbers in a sheet, with the units sold each month:

| | A | B | C |
|---|---|---|---|
| 1 | | Before | After |
| 2 | Complaints | 1 | 3 |
| 3 | Sold | 12 | 12 |

```localised
=ROUND((C2/B2-1)*100,0)      200
=ROUND(B2/B3*100,1)          8.3
=ROUND(C2/C3*100,1)          25
```

From 1 to 3 is indeed a 200% rise, and on twelve units the complaint rate went from 8.3% to 25%.
**It is two more complaints.** On a base of twelve, every single case moves the rate by more than
eight points, so the difference between a good month and an alarming one is one customer having a
bad day. Twelve units cannot tell a faulty product from bad luck; they can tell you to keep watching.

The same goes for rankings. A store that sold twelve of a new armchair and had two returned has a return
rate of 16.7%, probably the worst on the page, and one return fewer would make it 8.3%:

```localised
=ROUND(2/12*100,1)      16.7
=ROUND(1/12*100,1)      8.3
```

Three habits keep small bases in their place:

- **Show the count beside the rate.** "25% (3 of 12)" lets the reader see how little stands behind
  it; "25%" alone does not.
- **Do not rank on rates with very different bases.** A store with twelve sales and one with twelve
  hundred do not belong in the same league table of return rates.
- **Agree a minimum before anybody looks.** Varanda's rule, which Lívia added to the cards of
  lesson 10, is that a rate on fewer than thirty cases is shown greyed out and never ranked. Thirty is a
  convention, not a law; how sure a given number of cases can make you is a question for
  `statistics` lessons 10 and 12.

## Points and percent

Lesson 10's delivery KPI went from 76.9% in February to 86.2% in May. How much did it rise? There
are two right answers.

In A4 of the same sheet type `On promise %`, then 76.9 in B4 and 86.2 in C4:

```localised
=C4-B4                     9.3
=ROUND((C4/B4-1)*100,1)    12.1
```

**9.3 percentage points**, the difference between the two rates;
or **12.1 percent**, the rise relative to where it started. Both are correct, and a sentence that
says "up 9.3%" or "up 12.1 points" is wrong. The difference gets large when the rate is small: when
conversion goes from 1.25% to 1.5%, that is a quarter of a point, or a 20% rise:

```localised
=1.5-1.25                      0.25
=ROUND((1.5/1.25-1)*100,0)     20
```

"Conversion up 20%" and "conversion up 0.25 points" describe the same month, and the first will be
the one on the slide. **Write "points" for a difference between two percentages, and "percent" for a
relative change, and when it matters give both.** A reader who is told only the larger one has been
told the truth in its most flattering form.

## The five, together

Every number in this lesson was computed correctly. The average, the cumulative total, the rate
without its denominator, the total that mixes parts, and the percentage on twelve cases: **each
misleads by what it leaves out, not by what it gets wrong**, and each is cured by putting the missing
thing back beside it. The median beside the mean, the active customers beside the registered ones,
the denominator under the rate, the rows under the total, the count beside the percentage. How the
same kinds of omission turn up in charts, where an axis or an area does the leaving out, is the
subject of `visualization` lesson 16.
