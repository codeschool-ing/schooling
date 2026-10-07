---
title: Four questions
version: 1
---

Threat modelling has a reputation for being a heavyweight exercise: a specialist, a week of
workshops and a hundred-page document that nobody opens again. That picture describes a way of
doing it badly. **Threat modelling is analysing a representation of a system to find what can go
wrong with it, before or while it is built, and deciding what to do about each thing found.** It
can take twenty minutes at a whiteboard, and most of the time that is the version worth having.

The clearest statement of the method fits on one line. Adam Shostack, who led threat modelling at
Microsoft for years and wrote the field's standard textbook, reduced it to **four questions**:

1. **What are we working on?**
2. **What can go wrong?**
3. **What are we going to do about it?**
4. **Did we do a good enough job?**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-four-questions\" aria-label=\"The four questions as a loop. One: what are we working on, answered with a model of the system. Two: what can go wrong, answered with a list of threats. Three: what are we going to do about it, answered with mitigations and decisions. Four: did we do a good enough job, answered with a review. An arrow from the fourth returns to the first when the system changes.\"><defs><marker id=\"l01-four-questions-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-four-questions-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l01-four-questions-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"97.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  What are we</text><text x=\"97.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">working on?</text><rect x=\"30.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"97.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a model of the system</text><path d=\"M97.5 120.0 L97.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"195.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  What can</text><text x=\"272.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">go wrong?</text><rect x=\"205.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a list of threats</text><path d=\"M272.5 120.0 L272.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"447.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  What are we going</text><text x=\"447.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">to do about it?</text><rect x=\"380.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"447.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigations, decisions</text><path d=\"M447.5 120.0 L447.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"545.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4  Did we do a good</text><text x=\"622.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">enough job?</text><rect x=\"555.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"622.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a review</text><path d=\"M622.5 120.0 L622.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><path d=\"M175.0 85.0 L195.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M350.0 85.0 L370.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M525.0 85.0 L545.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M622.0 184.0 L622.0 240.0 L97.0 240.0 L97.0 184.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-amber)\"></path><text x=\"360.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">when the system changes, start again</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">Shostack’s four questions</text></svg>", "caption": "Each question has an answer you can hold in your hand. The fourth one is the one teams skip."}
```

Every method in this course is a way of answering one of them more carefully. A data flow diagram
(lesson 2) answers the first. STRIDE (lesson 3), PASTA (lesson 4), attack trees and LINDDUN
(lesson 5) are structured ways of answering the second. Security requirements (lesson 8), risk
numbers (lessons 9 to 11) and recorded decisions (lesson 12) answer the third. The fourth is a
review, and lesson 15 makes it a habit rather than an event.

### Each answer is something you can hold

The questions are useful because each has a concrete output, and you can tell whether the output
exists:

| question | what answering it produces |
|---|---|
| What are we working on? | a drawing of the system: its parts, the data moving between them, where trust changes |
| What can go wrong? | a list of threats, each one tied to a part of the drawing |
| What are we going to do about it? | for each threat, a decision: mitigate, eliminate, transfer or accept, with an owner |
| Did we do a good enough job? | a check that the drawing still matches the system and every threat has a decision |

A meeting that ends without the second column has been a conversation about security. That can be
useful, and it is not a threat model.

### The manifesto

In 2020 a group of practitioners, Shostack among them, published the **Threat Modeling
Manifesto**. Its five value statements are worth reading because each one names the bad habit it
replaces:

- a culture of finding and fixing design issues **over checkbox compliance**;
- people and collaboration **over processes, methodologies and tools**;
- a journey of understanding **over a security or privacy snapshot**;
- doing threat modelling **over talking about it**;
- continuous refinement **over a single delivery**.

The second line matters for this course. You will meet a dozen named methods and one tool, and
none of them is the point. They are scaffolding for people who know the system, sitting together
and asking what can go wrong with it. A method applied by somebody who has never seen the system
produces a list of generic threats that fits every system equally badly.

### Who asks the questions

**The people who build and run the system**, with somebody who knows security in the room or
reviewing afterwards. A developer knows that the reminder job runs with the database owner's
password because it was quicker. An operator knows the admin console is reachable from the clinic
Wi-Fi. A security specialist knows which of those facts matters. Nobody holds all three on their
own, which is why a model drawn by one person alone finds less than one drawn by three.
