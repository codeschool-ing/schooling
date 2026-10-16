---
title: Sign-off
version: 1
---

**Sign-off is the client's written statement that a release is accepted**: that it meets the
acceptance criteria agreed for it, or meets them well enough, and may go live. It is easy to read
as a formality, a signature at the bottom of a test report. It is the one moment in the project
where the person who carries the risk of a release says, in writing, that they accept that risk,
and it is worth exactly as much as the criteria it refers to.

## What a sign-off says

The form varies from an e-mail to a contract annex, and the content does not. A sign-off for
boxoffice names:

- **the build**, exactly: boxoffice 1.1, the one the session used, and not "the new version";
- **the criteria** and the result of each, passed or failed, as the session recorded them;
- **the open defects**, each with the client's decision: must be fixed first, or accepted for now;
- **the conditions**, if any, under which the acceptance holds;
- **who** accepts, and **when**.

In a project done under contract, sign-off is often what releases a payment, which is why vague
criteria do the most damage here. "Students get a fair price" invites an argument on the day money
changes hands; "the total is R$ 80,00" ends one.

## The manager's decision on 1.1

After the afternoon of section 04 of this lesson, the criteria stood like this: the student
scenario failed, the other three passed. The manager had three ways to answer, and they are the
three a client always has.

**Accept.** Sign, and 1.1 goes live as it is. Not possible here by her own words: students are a
large share of the theatre's audience and she will not refund them by hand.

**Accept with conditions.** Sign, provided something is done. She could accept 1.1 with the
student box removed from the form until it is fixed, and sell student tickets at the counter at
half price by hand in the meantime. A conditional sign-off is a real decision, and its conditions
are written down with the same care as the criteria, because each one is a promise somebody has to
keep.

**Reject.** Do not sign; the release goes back to be fixed. This is what she chose, and the reason
she gave is the most useful thing in the document: "the school groups book on Tuesday".

**None of the three is the tester's to choose.** Ana's part was to make the decision informed: every
criterion run, every finding written down in the manager's words, every open defect listed with
its consequence. A tester who says "I wouldn't release this" in the meeting has not done anything
wrong, and the decision is still not theirs.

## What happens after a no

A rejection is not the end of UAT; it starts a loop that most releases go round at least once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l12-signoff-loop\" aria-label=\"A loop of boxes. UAT session, the client drives, leads to the client decides, and signs, or not. Accept leads right to goes live, with its conditions. Reject leads down to Rui fixes it, a new build, 1.2, then left to sanity, then regression, lessons 9 and 10, then back up to the UAT session to rerun the failed criteria. A dashed arrow from the decision leads to a separate box, change request, own criteria, a later release.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">UAT session</text><text x=\"105.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the client drives</text><rect x=\"265.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the client decides</text><text x=\"350.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and signs, or not</text><rect x=\"510.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goes live</text><text x=\"595.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">with its conditions</text><rect x=\"265.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Rui fixes it</text><text x=\"350.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a new build, 1.2</text><rect x=\"20.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sanity, then regression</text><text x=\"105.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lessons 9 and 10</text><rect x=\"510.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">change request</text><text x=\"595.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">own criteria, a later release</text><path d=\"M192.0 56.0 L262.0 56.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M437.0 56.0 L507.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"472.5\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">accept</text><path d=\"M350.0 84.0 L350.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"358.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reject</text><path d=\"M263.0 194.0 L193.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M105.0 166.0 L105.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"113.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rerun the failed</text><text x=\"113.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">criteria</text><path d=\"M425.0 84.0 L530.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path></svg>", "caption": "What follows a rejected release. The fix goes round the loop and returns to the client; a change request leaves it and starts its own."}
```

Rui fixes `discount` and the build becomes 1.2. The team checks the fix itself with a sanity test
(lesson 9), then runs the regression suite (lesson 10), because a fix to the function that decides
every price is the kind of change that breaks a neighbour. Only then does the build go back to the
manager, and she does not repeat the whole afternoon: she reruns the failed criterion, plus whatever
the change could have touched, which here is all four, since they are all about price.

The change request about the counter travels separately. It is a new requirement, so it gets its
own criteria, written with the manager the same way as section 03 of this lesson, and its own turn
through the loop in a later release. Mixing it into the fix would hold the student discount back
for a discussion about the counter, and the school groups book on Tuesday.

## What a signature does not mean

**A sign-off does not say the release has no defects.** It says the client knows which ones it has
and accepts them. 1.2 may still carry the misspelt messages and the late refund that lesson 11
found, listed as open and accepted. That is a normal sign-off, and an honest one: the manager will
not be surprised by them, because they are written above her name.

Nor does it end testing. Production brings real customers, real phones and a real Tuesday, and
lesson 15 starts on how what they find is reported.
