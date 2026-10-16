---
title: Where the authority comes from
version: 1
---

On the Monday Tomás announces the role, Renata acquires a title. It is tempting to think that the
title is where her authority now comes from: she is the architect, so structural decisions are hers.
**A title gives an architect the right to decide; it does not make anybody follow the decision.**
The authority that makes decisions stick comes mostly from somewhere else, and an architect who
relies on the title alone finds this out quickly.

## Two kinds of authority

**Formal authority** comes from the organisation. It is the title, the CTO's announcement, a line in
a document that says who decides what. It is granted, it can be taken away, and it is the same on
the first day as on the last.

**Earned authority** comes from the people who work with the architect. It is built from a track
record of decisions that turned out well, from explanations that made sense, from admitting the
decisions that did not, and from relationships with the teams. It is not granted by anybody. It
grows slowly, it differs from one team to the next, and it can be spent.

Renata starts with an unusual mix of the two. Her formal authority is new and untested. Her earned
authority is large in some places: she wrote a good part of the original Payments code, and Bruno's
team trusts her judgement about it. It is close to nothing in others. The Driver app is a mobile
codebase she has never worked on, and Diego Araújo's team knows her only as the person who once
broke their build with a change to a shared API.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A two by two grid. Horizontal axis: earned authority, from low to high. Vertical axis: formal authority, from low to high. Low formal and low earned: an engineer with opinions. High formal, low earned: obeyed in the letter and worked around. Low formal, high earned: influence without a mandate, where Renata stood before the title. High formal and high earned: decisions that stick, with the title rarely used, where Renata stands with the Payments team. With the Driver team she has the title and little trust.\"><defs><marker id=\"auth-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M130 300 L690 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#auth-ah)\"></path><path d=\"M120 290 L120 24\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#auth-ah)\"></path><text x=\"400\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">earned authority: track record, explanations, relationships</text><text x=\"64\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">formal</text><text x=\"64\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">authority:</text><text x=\"64\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the title</text><rect x=\"130\" y=\"168\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">an engineer</text><text x=\"265.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">with opinions</text><rect x=\"130\" y=\"30\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">obeyed in the letter,</text><text x=\"265.0\" y=\"75.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">worked around in practice</text><rect x=\"410\" y=\"168\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">influence</text><text x=\"545.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">without a mandate</text><rect x=\"410\" y=\"30\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decisions that stick;</text><text x=\"545.0\" y=\"75.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the title is rarely used</text><circle cx=\"610\" cy=\"122\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"600\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Renata, with Payments</text><circle cx=\"190\" cy=\"122\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"202\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Renata, with Driver</text><circle cx=\"610\" cy=\"260\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"600\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Renata, before the title</text></svg>", "caption": "The title moves an architect up; only the teams can move one to the right. Renata starts in two different squares at once, depending on which team she is talking to."}
```

## What happens with only one

**Formal authority alone produces compliance and workarounds.** A team told to do something by
somebody they do not trust will do it in the letter: the design follows the instruction, and the
problems it causes are not reported, because reporting them would only bring another instruction.
Worse, teams stop telling the architect things early. An architect who is avoided learns about
decisions after they have been made.

**Earned authority alone produces influence without a mandate.** This was Renata before the title.
Teams asked her advice and usually took it, but when two teams disagreed about a seam, nobody could
settle it, and the cross-team incidents of the previous section happened in exactly that gap.

What makes the role work is the combination: **enough formal authority to settle what must be
settled, and enough earned authority that it rarely has to be used.** The title is best thought of
as a reserve. Every time it is used to overrule a team that disagrees, some earned authority is
spent, and it has to be built back.

## How earned authority is built

There is no shortcut, but there are habits that reliably build it and habits that reliably destroy
it.

It is built by:

- **showing the reasoning, not only the conclusion.** A team that can see why a decision was made
  can argue with it, and a decision that has survived an argument is trusted more;
- **being right in ways people can check.** Renata's first useful act as architect was the list of
  five hidden connections to the monolith's database in lesson 2: anybody could verify it, and it
  explained an incident two teams had been arguing about for months;
- **saying "I was wrong" when it is true**, quickly and without a speech;
- **making teams faster.** An architect whose involvement delays a team pays for it in trust, even
  when the involvement was right.

It is destroyed by deciding things the architect does not understand, by changing position without
explaining why, and by turning up only to say no.

## The advice process

Renata's Thursday conversation with Kátia was a choice between two ways of working. She could decide
whether Matching gets its own database, which the title allowed. Or she could make sure the decision
was made well by the person closest to it. She chose the second, using a practice described by
Andrew Harmel-Law in his 2021 article "Scaling the Practice of Architecture, Conversationally".

**The advice process** has one rule: **anybody may make an architectural decision, provided that
before deciding they seek advice from everybody who will be meaningfully affected by it and from
people with relevant expertise.** The decider must ask and must listen. They are not obliged to
follow the advice they get. Harmel-Law pairs the rule with a few supports: decisions are written
down as records, an open forum meets regularly where decisions in progress are discussed, and the
architects' main contribution becomes giving good advice and keeping the process healthy, not
holding a veto.

At Carreto it works like this for Matching's database:

1. **Kátia decides**, because Matching is the team that will live with the result.
2. **She asks the people affected**: Bruno, because Payments reads data that Matching writes; the
   Shipper team, which reads the same `loads` table; and Paula Reis on Platform, who will run the
   new database.
3. **She asks the people with expertise**: Renata, who knows the history of the shared table, and
   Paula again, on what a new database costs to operate.
4. **She writes the decision down**, with the advice she received — including the advice she did not
   take, and why.

Renata's advice is to split the data in two steps rather than one, and Bruno's is to wait until
Payments has stopped reading `loads` directly. Kátia takes Renata's advice and not Bruno's, and
records why: the first step does not touch anything Payments reads.

## Why an architect would choose to give the decision away

At first sight the advice process makes the architect less powerful. In practice it does three
things a central architect cannot. **It scales**: fifty engineers make decisions in parallel instead
of queuing behind one person. **It puts decisions where the knowledge is**: Kátia knows Matching's
code far better than Renata does. And **it builds the earned authority that the role depends on**,
because advice that turns out well is remembered, and nobody resents advice they were free to
decline.

It is not a way of abolishing the role, and it has limits. It depends on people actually seeking
advice from those affected, and an architect has to notice when that is not happening. It does not
settle a case where two teams decide incompatible things about the same seam. And it does not say
who answers for a decision that goes wrong — which is where the next section begins.
