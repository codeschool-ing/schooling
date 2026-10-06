---
title: Three things that can go wrong with information
version: 1
---

Most people arrive at security holding one picture: **security means keeping secrets.** A locked
door, a password, a file nobody else can open. That picture is a third of the subject, and a
course built on it would miss most of what actually hurts an organisation.

Take the small bookshop this course follows. It sells online at `shop.example.com`, keeps its
orders in a database, and pays nine people. Ask what could go wrong with its information, and the
answers fall into three groups:

| what happens | example at the shop | what it damages |
|---|---|---|
| somebody reads what they should not | a stranger downloads the customer list | **confidentiality** |
| something changes that should not | a price drops from R$ 45.90 to R$ 4.59 | **integrity** |
| it is not there when it is needed | the shop's page stops loading on a Saturday | **availability** |

Those three words are the **CIA triad**. The letters have nothing to do with any intelligence
agency; they are the initials of three properties information can have or lose.

**Confidentiality** is information reaching only the people meant to have it. The customer list,
the salaries, a supplier's contract. It is lost by a leak, by a stolen laptop, by an employee
reading a payslip that is not theirs.

**Integrity** is information staying correct and complete, changed only by someone allowed to
change it and only in the way they meant. It is lost by tampering, but also by accident: a
script that rounds every price, a disk that corrupts a block, a spreadsheet pasted into the wrong
column. Integrity also covers the systems themselves. A server whose programs were quietly
replaced has lost integrity even if no data file changed.

**Availability** is information and systems being usable when they are needed. It is lost by a
crashed server, a flood of traffic, ransomware that encrypts the disk, or a backup nobody can
restore.

```schooling-figure
{"svg": "<svg id=\"sf-cia-triad\" viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The CIA triad as a triangle. At the top, confidentiality: only the right people read it; its opposite is disclosure, the customer list leaked. Bottom left, integrity: it stays correct; its opposite is alteration, a price changed. Bottom right, availability: it is there when needed; its opposite is destruction or denial, the shop offline.\"><polygon points=\"360,78 145,236 575,236\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></polygon><text x=\"360\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">information</text><rect x=\"250\" y=\"14\" width=\"220\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">confidentiality</text><text x=\"360\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">only the right people read it</text><text x=\"360\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lost by: disclosure</text><rect x=\"20\" y=\"236\" width=\"250\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">integrity</text><text x=\"145\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">it stays correct and complete</text><text x=\"145\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lost by: alteration</text><rect x=\"450\" y=\"236\" width=\"250\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">availability</text><text x=\"575\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">it is there when needed</text><text x=\"575\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lost by: destruction or denial</text></svg>", "caption": "Each corner is a property and, under it, the harm that takes it away."}
```

The triad earns its place because it turns a vague worry into a question with an answer. "Is
the shop secure?" cannot be answered. "Which of the three would a stolen laptop damage, and
which would a power cut?" can: the laptop threatens confidentiality, the power cut threatens
availability, and neither touches integrity. Lesson 2 builds the vocabulary of risk on top of
this, and lesson 3 uses it to decide what to do first.

**A useful habit from here on:** whenever you meet a control, ask which of the three it
protects. A password protects confidentiality. A checksum protects integrity. A second server
protects availability. Some controls protect more than one, and some protect one by costing
another, which is the subject of section 05 of this lesson.
