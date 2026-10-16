---
title: Three words people use as one
version: 1
---

**Most people arrive believing that quality assurance means testing, and testing means looking for
defects at the end.** That picture is not wrong about what testing is. It is wrong about how much of
quality assurance testing covers, and about when any of it happens.

Three words get used as one, and keeping them apart is the first useful thing this course can give you:

| | what it looks at | what it is for | when |
|---|---|---|---|
| **quality assurance** | the **process**: how the work is done | **preventing** defects from being made | from the first conversation |
| **quality control** | the **product**: what the work produced | **detecting** defects that were made | once there is something to examine |
| **testing** | the product, by examining or running it | finding defects, and information about risk | wherever there is something to examine |

Testing is the largest part of quality control, and quality control is one half of quality assurance.
The ISTQB glossary, the vocabulary most testing certifications are written in, draws the same line:
assurance is **process-oriented**, control is **product-oriented**. In a job advert the three words
blur, and a "QA engineer" spends most of the week testing. The distinction still matters, because it
says which half of the work is missing when a team only does one.

## Preventing

Prevention acts **before a defect exists**. It works on the requirement, the design, the habits of the
team, so that fewer mistakes are made at all:

- a requirement read aloud by somebody hunting for the second meaning, as the previous section did with
  *over-60s*;
- a checklist the team agrees a piece of work must meet before anybody calls it done, which lesson 12
  calls the definition of done;
- a code review, where a second person reads a change before it joins the rest;
- a rule the team adopts after a defect, so that the same kind does not happen twice, which is lesson
  18's subject.

None of these runs the software, and several of them happen before there is any software to run.
Examining a document or a design without executing anything has a name of its own, **static
testing**, and it is the one form of testing that also prevents.

## Detecting

Detection acts **after a defect exists** and before, or after, a customer meets it. Running the program
with chosen inputs and comparing what it does with what it should do is **dynamic testing**, and it is
what most of this course's hands-on work is. Monitoring a system in production is detection too, the
latest kind there is.

Detection has a limit that no amount of effort removes, and Edsger Dijkstra put it in one sentence at
a NATO conference in 1969: **testing can show the presence of defects, never their absence.** Four
correct answers from `tickets.py` proved nothing about the fifth input. Every test result is a
statement about the inputs that were tried and nothing else, which is why choosing them is a skill
and why lessons 6, 19 and 20 are about choosing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l01-two-halves\" aria-label=\"A row of six stages from left to right: idea, requirement, design, code, release, in use. Above the requirement, design and code stages sits a band labelled prevent, with three activities: read the requirement for a second meaning, review the design, review the change; nothing runs. Below the code, release and in-use stages sits a band labelled detect, with three activities: run it with chosen inputs, check the release, watch it in production; the program runs. The two bands overlap at the code stage.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">idea</text><rect x=\"128.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requirement</text><path d=\"M121.0 148.0 L127.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"236.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"286.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">design</text><path d=\"M229.0 148.0 L235.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"344.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"394.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">code</text><path d=\"M337.0 148.0 L343.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"452.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">release</text><path d=\"M445.0 148.0 L451.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">in use</text><path d=\"M553.0 148.0 L559.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"128.0\" y=\"22.0\" width=\"316.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"136.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">prevent</text><text x=\"436.0\" y=\"36.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">static: nothing runs</text><text x=\"178.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">read it for a</text><text x=\"178.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">second meaning</text><path d=\"M178.0 92.0 L178.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"286.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">review the</text><text x=\"286.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">design</text><path d=\"M286.0 92.0 L286.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"394.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">review the</text><text x=\"394.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">change</text><path d=\"M394.0 92.0 L394.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"344.0\" y=\"182.0\" width=\"316.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"352.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">detect</text><text x=\"652.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dynamic: the program runs</text><text x=\"394.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">run it with</text><text x=\"394.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">chosen inputs</text><path d=\"M394.0 170.0 L394.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"502.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">check the</text><text x=\"502.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">release</text><path d=\"M502.0 170.0 L502.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"610.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">watch it</text><text x=\"610.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">in production</text><path d=\"M610.0 170.0 L610.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "Prevention works on what is being planned and written, before there is anything to run. Detection needs something to run, so it starts at the code and never ends."}
```

## Why a team needs both

A team that only detects pays for every mistake twice: once to make it, and once to find and repair it,
and the second payment grows the later it is made. A team that only prevents has no way of knowing
whether its prevention works; a review that has never been checked against what escaped it is a ritual.

The two feed each other. Every defect detection finds is a question for prevention: **why was this
possible?** The sixty-year-old's ticket is a defect in `tickets.py`, and it is also evidence that the
team writes requirements in words that allow two readings and nobody reads them hunting for the second.
Fixing the code repairs one defect. Changing how requirements are read repairs a class of them.

That is the shape of the job this course describes: finding defects, yes, and then using each one to
make the next one less likely. A tester who only finds them is useful. A tester who also changes why
they happen is the one a team keeps.
