---
title: Requirements in the backlog
version: 1
---

A requirement in a CSV file is a promise. **It becomes work when it reaches the place the team
plans work from**, and that place is the backlog, with the same priority rules as every other item
on it. Security requirements that live in a separate document get done in a separate time, which
in practice means after everything else.

### Three shapes a requirement takes there

| shape | when it fits | at Vereda |
|---|---|---|
| **a story of its own** | the requirement is a feature somebody will use | R17, patients see and end their open sessions |
| **acceptance criteria on an existing story** | the requirement constrains a feature being built anyway | R13 on the story that redesigns the upload page |
| **a rule in the definition of done** | the requirement applies to every story of a kind | R10's ownership check, for every story that returns a patient's data |

The third shape is the most powerful and the least used. A rule in the definition of done is checked
on every story, and nobody has to remember the threat behind it. For example: "any new endpoint that
returns patient data checks that the data belongs to the signed-in patient, and has a test that asks
for somebody else's."

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l08-backlog-shapes\" aria-label=\"Three shapes a requirement takes in the backlog. A story of its own, for a feature somebody uses: R17, patients see and end their open sessions. Acceptance criteria on a story being built anyway: R13 on the story that redesigns the upload page. A rule in the definition of done, applied to every story of a kind: R10’s ownership check on every story that returns a patient’s data.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a story of its own</text><text x=\"120.0\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">R17: see and end</text><text x=\"120.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open sessions</text><rect x=\"260.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the upload page story</text><rect x=\"275.0\" y=\"110.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"128.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">criteria: R13,</text><text x=\"360.0\" y=\"141.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20 MB, PDF only</text><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">acceptance criteria</text><rect x=\"510.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"574.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"638.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done: R10 on each</text><text x=\"600.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">definition of done</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the third shape is checked on every story, without anybody remembering the threat</text></svg>", "caption": "One requirement becomes work; one rides on work already planned; one becomes a habit of the team."}
```

### Keeping the thread

Each backlog item carries the requirement's id, and the requirement carries the threat's. That is
all the thread needs. When daniel asks why a story about phone numbers is above a story about the
booking calendar, the answer is R19, which answers T17, which is the abuse case where a former
partner takes over a patient's account. A priority with a reason behind it survives the planning
meeting better than one without.

### Who decides the order

The product owner orders the backlog, and security items are no exception. What the threat model
contributes is the information to order them well: which objective each threat endangers, from
PASTA's stage 1, and how large the risk is, which lessons 9 to 11 put numbers on. A security
person who wants a requirement done first should be able to say why in those terms. If they cannot,
the order the product owner chose is probably right.
