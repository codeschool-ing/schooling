---
title: The Ishikawa diagram
version: 1
---

**An Ishikawa diagram lays out the possible causes of one problem by category, so the team looks in every
direction at once instead of following the first chain that occurs to somebody.** Kaoru Ishikawa developed it at
Japanese factories and spread it in the 1960s through the quality circles he championed; it is also called a
**cause-and-effect diagram**, or a **fishbone**, because of its shape.

The problem goes at the head, on the right. A spine runs to it, and from the spine grow the bones, one per category
of cause. On each bone the team writes the causes it can find in that category, and causes of causes as smaller bones
off them.

## Categories for software

Factories use six categories, often remembered as the six Ms: machine, method, material, man, measurement and milieu,
the environment. Software teams usually adapt them. Cine Aurora uses these six:

| bone | the question it asks |
|---|---|
| **requirements** | did the rule say what was needed, and did everybody read it the same way? |
| **process** | which step that should have caught it was missing, late or skipped? |
| **people** | what did the people involved know, and what were they never told? |
| **tools** | what did the tools check, and what did they let through without a word? |
| **environment** | how did the real world differ from the one the team built and tested in? |
| **measurement** | what would have shown the defect, and why was nobody looking at it? |

The categories are prompts, not boxes to fill. A bone with nothing on it is fine, as long as somebody asked.

## The Wednesday student

Cine Aurora drew one for lesson 6's defect, the student who paid R$ 9,00 on a Wednesday evening. It never reached a
customer, but only because Lia explored before the release, and the retrospective could not agree on a single chain
of whys for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l18-fishbone\" aria-label=\"An Ishikawa diagram. At the head, on the right: a student pays R$ 9,00 on a Wednesday. Six bones join the spine. Requirements: no sentence on combining. Process: no combination cases, and a review alone, a day late. People: new to pricing. Tools: no automated price checks. Environment: test sessions on Thursdays. Measurement: the report hides discounts.\"><path d=\"M20.0 150.0 L540.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"545.0\" y=\"112.0\" width=\"125.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607.5\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">student pays</text><text x=\"607.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">R$ 9,00 on a</text><text x=\"607.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Wednesday</text><path d=\"M155.0 40.0 L215.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"155.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">requirements</text><text x=\"171.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no sentence on combining</text><path d=\"M310.0 40.0 L370.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"310.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">process</text><text x=\"326.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no combination cases</text><text x=\"344.9\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">review alone, a day late</text><path d=\"M460.0 40.0 L520.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"460.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">people</text><text x=\"476.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">new to pricing</text><path d=\"M155.0 260.0 L215.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"155.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">tools</text><text x=\"171.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no automated price checks</text><path d=\"M310.0 260.0 L370.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"310.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">environment</text><text x=\"326.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">test sessions on Thursdays</text><path d=\"M460.0 260.0 L520.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"460.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">measurement</text><text x=\"476.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">report hides discounts</text></svg>", "caption": "Six categories, several causes, one defect. Removing any one of them would have stopped it earlier."}
```

Read the bones and the defect stops looking like one mistake:

- **requirements**: the first four sentences of the rule said nothing about combining discounts; the fifth sentence,
  *half price is the most*, only arrived after the defect;
- **process**: nobody wrote combination cases at planning, and Tomás reviewed the change alone, a day after it was
  written;
- **people**: Rafael had never worked on prices before, and Joana assumed "half" obviously could not be halved;
- **tools**: there were no automated checks on prices at all, so nothing ran the combination after each change;
- **environment**: the test sessions were on Thursdays, so the Wednesday rule was never exercised with another
  discount;
- **measurement**: the nightly report counted seats per session but not the discount given, so R$ 9,00 tickets
  would have looked like any other sale.

Several of those causes had to line up for the defect to get as far as it did, and removing any one of them would
have stopped it earlier. That is the normal shape of a defect that escaped, and it is what the diagram is for: **a team that finds
six causes gets to choose the cheapest ones to remove, instead of the first one somebody named.**

## Running the session

A fishbone session takes an hour. The tester often runs it, because a tester's habits, asking what else could
explain this, are the habits it needs.

1. Write the problem statement at the head, the precise one, and read it aloud.
2. Draw the six bones and go round them one at a time, asking the bone's question. Write every cause offered;
   argue later.
3. For the causes that look important, ask *why* again and add smaller bones. This is where the five whys fits
   inside the diagram.
4. Mark the causes the team agrees contributed, and pick actions for the ones that are cheapest to remove and would
   prevent the most.

The diagram is the conversation's record, and like every record in this course it is worth keeping where the next
analysis can find it. The second time a bone carries the same cause, the cause is the thing to fix.
