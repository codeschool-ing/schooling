---
title: Where the handoffs break
version: 1
---

Most wrong numbers in a company are not wrong calculations. **They are right calculations of
something slightly different from what the reader thinks, and the difference entered at a handoff**:
the moment one person's work became another person's input, and something that was in the first
person's head did not travel. With four roles there are several of those moments in every number.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Four boxes in a row joined by arrows: Tiago the data engineer, Lívia the analyst, Renata the marketing director, the campaign. Under each arrow, what has to cross it: between Tiago and Lívia, a change notice for the data; between Lívia and Renata, the written definition of a returning customer; between Renata and the campaign, the decision and who owns it.\" data-fig=\"l03-handoffs\"><rect x=\"10.0\" y=\"40.0\" width=\"130.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Tiago</text><text x=\"75.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">data engineer</text><rect x=\"200.0\" y=\"40.0\" width=\"130.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Lívia</text><text x=\"265.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">BI analyst</text><rect x=\"390.0\" y=\"40.0\" width=\"130.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Renata</text><text x=\"455.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">marketing director</text><rect x=\"580.0\" y=\"40.0\" width=\"130.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">the campaign</text><text x=\"645.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in May</text><path d=\"M142.0 72.0 L198.0 72.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M198.0 72.0 L189.9 75.9 L189.9 68.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"82.0\" y=\"130.0\" width=\"176.0\" height=\"78.0\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><path d=\"M170.0 76.0 L170.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"170.0\" y=\"154.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a change notice:</text><text x=\"170.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">&quot;cancelled orders</text><text x=\"170.0\" y=\"192.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leave on 1 March&quot;</text><path d=\"M332.0 72.0 L388.0 72.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M388.0 72.0 L379.9 75.9 L379.9 68.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"272.0\" y=\"130.0\" width=\"176.0\" height=\"78.0\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><path d=\"M360.0 76.0 L360.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the definition:</text><text x=\"360.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">&quot;bought again within</text><text x=\"360.0\" y=\"192.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">180 days&quot;</text><path d=\"M522.0 72.0 L578.0 72.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M578.0 72.0 L569.9 75.9 L569.9 68.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"462.0\" y=\"130.0\" width=\"176.0\" height=\"78.0\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><path d=\"M550.0 76.0 L550.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"550.0\" y=\"154.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the decision</text><text x=\"550.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and its owner,</text><text x=\"550.0\" y=\"192.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in writing</text><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a number breaks where nothing written crosses the arrow</text></svg>", "caption": "Renata's question as a chain of handoffs. Each arrow needs something written to cross it; the one that was missing in March moved the repeat rate by a point."}
```

## The repeat rate that moved by itself

On 1 March 2026 Tiago changed the online shop's pipeline so that cancelled orders no longer reached
the database. It was a good change, asked for by finance, and he mentioned it in a message to Otávio.
Nobody told Lívia.

Her repeat rate counted every customer whose first order was placed in the first half of 2025. **1,400 of those 41,200
customers had placed one order and then cancelled it**, and with cancelled orders gone they vanished
from the count. Nobody in the numerator changed: a customer whose only order was cancelled had never
come back. So the denominator shrank and the rate rose:

| | first-time customers | came back within 180 days | repeat rate |
|---|---|---|---|
| before 1 March | 41,200 | 11,900 | 28.9% |
| after 1 March | 39,800 | 11,900 | 29.9% |

A full point, overnight, with no customer behaving differently. Renata saw it in the March report and
asked what the campaign team had done right. **Both definitions were defensible; the problem was that
one replaced the other without anybody downstream knowing.** The arithmetic is lesson 12's hidden
denominator, met here as a handoff problem.

## "The number is different in my report"

This sentence is the most common symptom, and it usually has one of three causes:

- Two definitions. Finance counts a sale when it is invoiced, marketing when the order is placed.
  Both are right for their purpose; the reports disagree on every order placed on the last day of
  a month.
- Two copies. One report reads the database, another a spreadsheet somebody exported in January
  and has been updating by hand since.
- A silent change upstream, like Tiago's: one source changed, and only the reports built on it
  moved.

The answer is not to make one report agree with the other by adjusting it. It is to find which of the
three it is, and then decide which definition is the company's.

## Who owns a definition

**Every number that is shown regularly needs an owner: a person who decides what it means and is
told before it changes.** It is not the engineer, who moves data and should not decide what a
returning customer is; and not necessarily the analyst, who computes it. For the repeat rate it is
Renata, because she acts on it, with Lívia keeping the written definition. For revenue it is Otávio.
When nobody owns a number, the last person to change the code decides what it means, and nobody
finds out.

## What should cross each handoff

Four artefacts do most of the work, and none of them needs a tool:

| artefact | what it says | who writes it |
|---|---|---|
| a written definition | what is counted, what is excluded, over what period | the analyst, agreed with the owner |
| an entry in a data dictionary | what each column of each table means and where it comes from | the engineer and the analyst |
| a change notice | what changes in the data, from when, and which numbers will move | whoever makes the change |
| a data contract | what one team promises to deliver to another, and what happens if it breaks | the two teams together |

The data dictionary is the subject of `warehouse-modeling` lesson 12, and data contracts of
`data-governance` lesson 11. At Varanda's size, **the first and the third would have saved Renata's
question from the March surprise**: Lívia's definition said "first-time customers, January to June 2025", and it did not say whether a cancelled order made somebody a customer. After March it did, and Tiago's
changes now go to a short list of people who read them — Lívia first.
