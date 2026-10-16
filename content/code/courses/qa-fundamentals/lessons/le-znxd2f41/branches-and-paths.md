---
title: Branches, and the paths between them
version: 1
---

**Statement coverage asks whether each line ran. Branch coverage asks whether each decision went both
ways.** The difference matters for any `if` that does nothing when it is false: the line inside can run
every time, and nobody ever checks what happens when it does not.

## Branch coverage of the seven cases

`price` makes six decisions. With the seven cases from the previous section, each one goes both ways at
least once:

| decision | true in | false in |
|---|---|---|
| `time < "17:00"` | the 16:59 case | the others |
| `student` | the student of 20 | the others |
| `age > 60` | the sixty-one-year-old | the others |
| `age < 12` | the child of 11 | the others |
| `day == "wed"` | the Wednesday adult | the others |
| `half` | the student, the child, the sixty-one-year-old | the others |

**Full branch coverage**, then. Every decision has been true and false, so every arrow out of every `if`
has been followed. And still both defects from lessons 1 and 6 are in the code, untouched.

## Paths

A **path** is one route through the whole function, from the first decision to a `return`. Each decision
taken one way or the other sends the program down a different path, and the defects in `price` live not
in any one decision but in particular **combinations** of them.

Count the paths that can happen. The session is a matinée or not: two. The customer is a student or not:
two. Their age makes them a child, an adult, or over sixty: three. It is Wednesday or not: two. That is
two times two times three times two, **twenty-four combinations**, each a different path or a different
mix of reductions through the same ones. The seven cases take six of them; two of the seven, the evening
adult of 35 and the twelve-year-old, take the same one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 230\" role=\"img\" data-fig=\"l07-paths\" aria-label=\"A grid of customers against sessions. Rows: adult, child, over sixty. Columns: matinée, evening, Wednesday matinée, Wednesday evening. The seven cases take five of these cells: adult at a matinée, adult in the evening, child in the evening, over sixty in the evening, adult on a Wednesday evening. The four cells combining a child or someone over sixty with a Wednesday are outlined as never taken.\"><text x=\"216.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">matinée</text><text x=\"328.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">evening</text><text x=\"440.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Wed matinée</text><text x=\"552.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Wed evening</text><text x=\"150.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">adult</text><rect x=\"163.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"216.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">taken</text><rect x=\"275.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">taken</text><rect x=\"387.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"440.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never taken</text><rect x=\"499.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"552.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">taken</text><text x=\"150.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">child</text><rect x=\"163.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"216.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never taken</text><rect x=\"275.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">taken</text><rect x=\"387.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"440.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never taken</text><rect x=\"499.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"552.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never taken</text><text x=\"150.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">over sixty</text><rect x=\"163.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"216.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never taken</text><rect x=\"275.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">taken</text><rect x=\"387.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"440.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never taken</text><rect x=\"499.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"552.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never taken</text><text x=\"496.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">reduction and Wednesday: never taken</text></svg>", "caption": "Students are left out to fit; the student case sits in the evening column, and no student on a Wednesday was ever run either. The outlined cells are where the stacking defect lives."}
```

The figure leaves out students, to fit, and sets three kinds of customer against four kinds of session.
Five of the six covered paths sit in it. Look at where they are, and where the empty ones are. **Every path that combines
a reduction with a Wednesday is empty.** That is precisely where lesson 6 found the stacking defect from
the outside, by asking what the rule did not say. From the inside, the same gap shows up as a region of
paths nobody has taken.

## Why nobody aims for full path coverage

Twenty-four paths is manageable for a function of six decisions. Each new independent decision doubles
the count. A function with twenty independent `if`s has over a million paths, and a loop that can run
any number of times has more paths than can ever be counted. Full path coverage is, for real programs,
not a target anybody reaches.

What path thinking gives a tester instead is a **way of asking where to look**: which decisions interact,
so that their combinations matter, and which combinations no test has tried. Here the answer was
"reductions and Wednesday", which is exactly the pair of decisions that both change the price. A tester
does not need to enumerate twenty-four paths to see that; they need to look at the code and ask which
`if`s touch the same value.

That is the white-box version of the habit lesson 6 taught from the outside: **for every pair of
conditions, ask what happens when both are true.** Black box finds the pairs in the rule. White box finds
them in the code, including pairs the rule never mentions, because they exist in the code whether anybody
wrote them down or not.
