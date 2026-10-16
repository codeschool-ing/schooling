---
title: Answering for a decision
version: 1
---

*Accountable* is one of those words that people use for two different things. **Some hear it as "the
person who gets blamed"; others as "the person who has to do the work."** It is neither. To be
accountable for a decision is to be the person who answers for it: who explains what was decided and
why, who owns what follows when it goes wrong, and who makes sure the lesson changes something. It
is the third verb of the role, and the one that gives the other two their weight.

## Responsible and accountable

The distinction is old enough to have a well-known acronym. In a **RACI** chart every task names who
is *Responsible* (does the work), who is *Accountable* (answers for the result), who is *Consulted*
before it is done, and who is *Informed* afterwards. Several people can be responsible; **exactly
one should be accountable**, because a result two people answer for is a result nobody answers for.

The advice process from the previous section fits this vocabulary neatly. The person who decides is
accountable for the decision. The people who gave advice are consulted, and they answer for the
quality of their advice — which is a real obligation, but a different one. When Kátia decided how
Matching's data would be split, she became accountable for it, and Renata became answerable for the
advice she gave.

## Decision rights

Accountability only works when everybody knows **who has the right to decide what**. These are
called *decision rights*, and most companies have them only implicitly: they live in habits and
memories, and they are discovered when two people both believe a decision was theirs.

The cross-team incident that led Tomás to create the role was exactly that. Matching believed the
way a load's status was stored was Matching's to change, and Payments believed the same about
Payments. Both were partly right, and nothing written anywhere said otherwise. **A decision right
that is not written down is settled by whoever moves first.** Renata's page on her first Friday
proposed owners for nine open questions, and that was a first, small list of decision rights. Lesson
16 draws up the fuller version for Carreto, deciding which decisions belong to the architect, which
to the tech leads and which to the teams.

## A spectrum of ways to decide

Between "the architect decides" and "the team decides" there are several positions, and an architect
chooses among them every time a decision comes up. The idea of a continuum of decision styles is
older than software: Robert Tannenbaum and Warren Schmidt drew one for managers in the *Harvard
Business Review* in 1958. For architectural decisions, five positions are enough:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Five boxes from left to right. One: the architect decides alone, for example an incident at three in the morning. Two: the architect decides after consulting, for example a standard for every service. Three: architect and teams decide together, for example who owns the loads table. Four: the team decides after seeking advice, for example Matching&#x27;s own database. Five: the team decides and informs, for example a library inside one service. Leftwards means faster and more control for one decision; rightwards means more ownership and it scales to many decisions.\"><defs><marker id=\"spec-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"75.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the architect</text><text x=\"75.0\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decides alone</text><rect x=\"10\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an incident at</text><text x=\"75.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">three in the morning</text><rect x=\"150\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"215.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the architect</text><text x=\"215.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decides after</text><text x=\"215.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">consulting</text><rect x=\"150\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"215.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a standard every</text><text x=\"215.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">service follows</text><rect x=\"290\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"355.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">architect and</text><text x=\"355.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teams decide</text><text x=\"355.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">together</text><rect x=\"290\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"355.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">who owns the</text><text x=\"355.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">loads table</text><rect x=\"430\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"495.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the team decides</text><text x=\"495.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">after seeking</text><text x=\"495.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">advice</text><rect x=\"430\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"495.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Matching's</text><text x=\"495.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">own database</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"635.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the team decides</text><text x=\"635.0\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and informs</text><rect x=\"570\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a library inside</text><text x=\"635.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one service</text><text x=\"10\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">who decides, from the architect to the team</text><path d=\"M360 262 L40 262\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#spec-ah)\"></path><path d=\"M360 262 L680 262\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#spec-ah)\"></path><text x=\"20\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">faster, more control,</text><text x=\"20\" y=\"299.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for one decision</text><text x=\"700\" y=\"285.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">more ownership,</text><text x=\"700\" y=\"299.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">scales to many decisions</text></svg>", "caption": "Five ways to decide, from the architect alone to the team alone. Two are highlighted: the Pix retry in this lesson was decided at 1, and it belonged at 4, where Matching's database was decided."}
```

No position is right in general. **The choice depends on what the decision is like**, and four
questions sort most cases:

| question | pushes towards the architect deciding | pushes towards the team deciding |
|---|---|---|
| how expensive is it to reverse? | very expensive, or involves money or regulation | cheap; a two-way door |
| how many teams does it affect? | several, with conflicting interests | one |
| how urgent is it? | an incident, where somebody must decide now | there is time to ask |
| where is the knowledge? | spread across teams, or held by the architect | inside the team |

Matching's database sat at the fourth position: expensive to reverse, but the knowledge was in the
team, and there was time to ask. An incident at three in the morning sits at the first: somebody has
to decide, and a meeting is the wrong tool. Most decisions inside one team sit at the fifth, and an
architect who pulls them to the left has become the approver of everything from the start of this
lesson.

## When it goes wrong

In Renata's third week, as lesson 2 described, Bruno brought her the plan for paying drivers by Pix.
On the question of what to do when the bank's API takes too long to answer, he asked for a quick
call. Renata answered it herself, in ten minutes, at the first position on the spectrum: retry up to
three times. She knew the bank's API had an identifier for each payment, and assumed the bank would
refuse a second request with the same identifier. Nobody checked. The bank's API refuses duplicates
only when the request carries a separate idempotency key, and Carreto's requests did not send one.

In the first week of live payouts, the bank was slow on a Friday afternoon. Two drivers were paid
twice: one payout of R$ 2,850 and one of R$ 4,100, R$ 6,950 in all. Ícaro Nunes, the junior
developer on Payments, had written the retry code exactly as it was specified.

What Renata did next is what answering for a decision looks like:

1. **She said it was hers, first and in public.** In the incident review she said that she had made
   the decision alone, quickly, on an assumption she had not checked. She did not wait to be asked,
   and she did not let the review drift towards the code Ícaro wrote, which did what it was told.
2. **She explained the reasoning at the time.** What she knew, what she assumed, and why the
   assumption looked safe. This is what makes an account useful rather than merely contrite: the
   next person can see where the reasoning broke.
3. **She made sure the damage was dealt with.** The fix — sending an idempotency key with every
   request — went out the following Monday. Sílvio Matos's team contacted both drivers about
   recovering the duplicate payments.
4. **She changed the process, not only the code.** Decisions that move money now go through the
   advice process, however small they look, and the question "what happens if this request is sent
   twice?" is asked of every design that talks to the bank.

Two things are worth noticing. **Answering for a decision is not the same as being at fault for
everything around it**: the bank's documentation was unclear, and the review found that too. And the
mistake was not the retry policy as much as the position on the spectrum. A decision that involves
money and an outside system belonged at the fourth position, and taking it at the first, to save a
meeting, is what removed the people who would have asked about the key. The incident review followed
the blameless format that `architect-communication` lesson 15 teaches in depth.

## Authority and accountability belong together

The section before this one ended with a gap: the advice process says who decides, but not who
answers. This section's answer is that **whoever decides answers**, and the two should not be
separated. **Accountability without authority is a trap**: an architect blamed for decisions they
had no right to make learns to avoid the role. **Authority without accountability is worse**: an
architect who decides and never answers for the outcome stops learning from it, and the teams
quietly stop trusting the decisions.

Renata's earned authority did not fall after the double payouts. With Bruno's team it rose, because
the people who saw how she handled it were the ones who had expected her to blame the junior
developer. That is one more way the two kinds of authority from the previous section differ: the
title cannot be increased by admitting a mistake, and trust often is.
