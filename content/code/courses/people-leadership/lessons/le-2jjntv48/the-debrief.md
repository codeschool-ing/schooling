---
title: Running the debrief, and calibrating the interviewers
version: 1
---

The debrief is where the evidence from four interviews becomes a decision. **A good one is short,
discusses evidence rather than impressions, and ends with a decision and its reasons written down.**
A bad one is a conversation about whether people liked the candidate, won by whoever spoke first.

## Lucas's debrief

Lucas was one of six candidates in Agenda's final round. When the debrief started, all four
interviewers had submitted their written feedback, and everybody had read it. The scores were:

| interviewer | area | score | the evidence in one line |
|---|---|---|---|
| Diego | running a service in production | 3 | described a real incident clearly, including what he changed afterwards |
| Yara | writing and testing code | 4 | wrote a failing test before touching the bug, explained each step |
| Helena | explaining a trade-off | 2 | real example, but stayed technical and did not check understanding |
| Renata | working with others | 3 | specific example of disagreeing in review and changing his mind |

## How Renata ran it

**She started with the disagreement.** The room did not need to discuss Yara's 4; the evidence was
clear and nobody doubted it. It needed to discuss Helena's 2, because it was the lowest score, on a
must, and the decision could turn on it.

**She asked for evidence, not opinions.** "What did he say that put it at 2 rather than 3?" Helena
read from her notes: Lucas had explained a caching decision to a support colleague in terms of cache
invalidation and time-to-live, and when asked how he knew she understood, said she had not asked any
questions.

**She asked whether anybody had evidence on the same point from their own interview.** Diego had: in
describing his incident, Lucas had explained the impact to the clinic owners in plain terms, in what
Diego wrote down as "the reminder went out an hour late for about two hundred patients". That was not
Helena's question, but it was evidence about the same must, and it went into the notes.

**She decided against the rule written in advance.** Caju's rule for this role was: an offer needs at
least a 3 on two of the three musts and no 1 on any. Lucas had 3 and 4 on two musts and a 2 on the
third, with some contrary evidence. Renata decided to make the offer, and wrote in the decision record
that the third must was the area to support in his first months, which lesson 18's onboarding plan
picked up.

**She spoke last**, as the previous section's rule required, and only after everybody else had said
whether they agreed. Helena said she still had doubts and would have scored him a 2 again; that went in
the record too. A decision with a recorded dissent is more honest than a unanimous one reached by
anchoring.

## Calibrating the interviewers

The debrief decides one candidate. Calibration looks across many. After the round, Renata laid out
every score from every interviewer for all six candidates.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-calibration\" aria-label=\"A dot chart with four interviewers in rows and scores from 1 to 4 across. Each row has six dots, one per candidate in the final round. Yara’s, Helena’s and Renata’s dots spread across the lower part of the scale too. Diego’s sit at 3 and 4 only, and are higher than the others’ for five of the six candidates.\"><path d=\"M160.0 40.0 L160.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"160.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M313.3 40.0 L313.3 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"313.3\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M466.7 40.0 L466.7 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"466.7\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M620.0 40.0 L620.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"620.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"390.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">score on the rubric, six candidates per row</text><text x=\"130.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Diego</text><circle cx=\"454.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"466.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"478.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"608.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"620.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"632.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><text x=\"130.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Yara</text><circle cx=\"307.3\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"620.0\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"160.0\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"460.7\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"472.7\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"319.3\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><text x=\"130.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Helena</text><circle cx=\"295.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"307.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"160.0\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"319.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"466.7\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"331.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><text x=\"130.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Renata</text><circle cx=\"301.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"454.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"313.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"466.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"325.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"478.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "Diego’s 3 and Helena’s 3 may not mean the same thing. The pattern is invisible from inside one debrief."}
```

One pattern stood out. Diego's scores were higher than everybody else's for five of the six candidates,
and never below 3. That did not mean Diego was wrong. It meant his 3 and Helena's 3 might not mean the
same thing, and a candidate's chance of an offer depended partly on who interviewed them.

Three things help, and Caju does all of them:

- **Shadowing.** A new interviewer sits in on a few interviews before running their own, and an
  experienced one sits in on a new interviewer's first few, then they compare scores.
- **Calibration sessions.** Twice a year, the interviewers for a role score the same written answers
  independently and compare. The disagreements show where the scale's wording is unclear.
- **Looking back.** After a year, Renata compares interview scores with how the people hired actually
  did. Over many hires, an interviewer whose scores predict nothing is worth noticing; over one or two,
  it is chance.

Renata showed Diego the chart, privately. He had not known. He read his own write-ups again and agreed
that he had been scoring how much he liked talking to the candidate. **Nobody can see their own
leniency without the numbers beside everybody else's**, which is why the comparison has to be made by
somebody, on purpose.

## Your task

For a decision made by a group that you were part of, at work or elsewhere, write down in your notebook
the order in which people spoke and whether anybody changed their view during the discussion. Then
check:

- Who spoke first, and did the final decision match their opinion?
- Was the most senior person's view known before the others spoke?
- Was any disagreement written down, or did it disappear into the decision?
