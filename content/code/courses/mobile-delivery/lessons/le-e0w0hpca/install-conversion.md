---
title: Install conversion, and when a difference is real
version: 1
---

**A test of the store page compares two conversion rates, and the question is never which is higher;
it is whether the difference is larger than chance.** With few visitors, two identical pages will show
different rates every day. Both stores answer the question with a confidence range; this section
computes one, so the range is not a number you take on trust.

## Two variants of the planner's page

Variant A is the current page. Variant B puts the week with its total first among the screenshots,
lesson 4's advice. The script takes the visitors and installs of each, and prints each rate, the
difference, and a **95% confidence interval** for the difference: the range that, by the usual
normal approximation, would contain the true difference in 95 of 100 tests like this one. Save this
as `conversion.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "conversion.ts", "parts": [{"code": "// conversion.ts: two variants of the store page, and whether the difference between them is larger than chance\nconst [visitsA, installsA, visitsB, installsB] = process.argv.slice(2, 6).map(Number);\nconst a = installsA / visitsA;\nconst b = installsB / visitsB;", "note": "Visitors and installs for each variant, from the command line, and each variant's conversion rate."}, {"code": "const se = Math.sqrt((a * (1 - a)) / visitsA + (b * (1 - b)) / visitsB);\nconst low = b - a - 1.96 * se;\nconst high = b - a + 1.96 * se;", "note": "The standard error of a difference between two proportions, and 1.96 of them either side: the usual 95% interval."}, {"code": "const pts = (x: number) => `${(100 * x).toFixed(1)}`;\nconsole.log(`A ${pts(a)}%  B ${pts(b)}%  difference ${pts(b - a)} points, 95% interval ${pts(low)} to ${pts(high)}`);\nconsole.log(low > 0 ? \"B converts better\" : high < 0 ? \"A converts better\" : \"not enough evidence either way\");", "note": "The verdict follows the interval: entirely above 0, entirely below, or straddling it."}]}
```

Run it twice: with a fortnight of visitors, and with the first day's tenth of them:

```
ana@dev:~/planner$ node conversion.ts 4200 1176 4180 1296
A 28.0%  B 31.0%  difference 3.0 points, 95% interval 1.1 to 5.0
B converts better
ana@dev:~/planner$ node conversion.ts 420 118 418 130
A 28.1%  B 31.1%  difference 3.0 points, 95% interval -3.2 to 9.2
not enough evidence either way
```

## Reading the two runs

**With about 4200 visitors per variant, B's 3 points are real**: the interval runs from about 1 to 5
points and does not reach 0. **With about 420, the same rates prove nothing**: the interval runs from
about -3 to 9 points, so the true difference could as easily be zero, or negative. The page did not
change between the two runs; only the number of people who saw it did.

That is the lesson for reading the consoles too. **Stop a test when its sample is large enough, not
when the difference looks good**; a team that checks every morning and stops on the first good day
will "find" a winner in a test between two identical pages.

## What conversion does not measure

A page that converts more can attract people who leave in week 1, lesson 17. The better test reads
both: the conversion of each variant, and the week-1 retention of the people each one brought. A page
that promises less and keeps more is the better page.
