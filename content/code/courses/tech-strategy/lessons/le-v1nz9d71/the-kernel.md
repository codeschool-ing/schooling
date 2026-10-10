---
title: The kernel: diagnosis, guiding policy, coherent action
version: 1
---

Rumelt's definition is short. A good strategy has a **kernel** of three parts: a diagnosis, a
guiding policy and a set of coherent actions. It may carry other things — a vision, numbers, a
timeline — but without those three it is not a strategy, however well it is written.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three boxes left to right joined by arrows. Diagnosis: what is going on, and which part of it matters. Guiding policy: the approach that deals with it, which rules things out. Coherent actions: steps that reinforce each other. Under each box, the question it answers.\"><defs><marker id=\"kern-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Diagnosis</text><text x=\"120\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what is going on,</text><text x=\"120\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and which part</text><text x=\"120\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">of it matters</text><path d=\"M226 100 L254 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#kern-ah)\"></path><rect x=\"260\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Guiding policy</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the approach that</text><text x=\"360\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deals with it, and</text><text x=\"360\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what it rules out</text><path d=\"M466 100 L494 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#kern-ah)\"></path><rect x=\"500\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Coherent actions</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">steps with people</text><text x=\"600\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and money behind them,</text><text x=\"600\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">that reinforce each other</text><text x=\"120\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">“What is the problem?”</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">“How will we deal with it?”</text><text x=\"600\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">“What do we do on Monday?”</text><rect x=\"20\" y=\"222\" width=\"680\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a list of goals has none of the three: it starts where the actions should end</text></svg>", "caption": "The kernel. Each part answers a different question, and each depends on the one before it: a policy without a diagnosis is a guess, and actions without a policy are a list."}
```

## Diagnosis: what is going on, and which part matters

A diagnosis **names the challenge and simplifies it**. Any real organisation has dozens of
problems at once; the diagnosis says which one is critical, and why the others can wait. It is a
judgement, and the judgement is what makes it useful — a diagnosis listing every problem is the
goal list again with different verbs.

A good diagnosis has evidence a reader could check. "Our architecture is not scalable" is an
opinion. "Checkout fails during the first ten minutes of every big on-sale, and the failures come
from one module that every team edits" is a diagnosis, because somebody could open the incident
log and confirm or refute it.

## Guiding policy: the approach, and what it rules out

The guiding policy is **the overall approach chosen to deal with the diagnosis**. It is not an
action and not a goal: it is a direction that makes the next hundred small decisions easier,
because people can ask whether a proposal fits it.

**A policy earns its place by what it excludes.** "Improve reliability" excludes nothing. "Protect
the on-sale before anything else" excludes a lot: it says that when a reliability fix on the
on-sale path competes with a feature, the fix goes first, and that a proposal unrelated to the
on-sale has to wait its turn. Rumelt compares a guiding policy to a signpost: it does not tell you
every step, but it stops you walking in every direction at once.

## Coherent actions: steps that reinforce each other

The actions are **what the organisation will actually do**: who, with what money, starting when.
They have to be coherent — each one makes the others work better, rather than each team pursuing
its own item and hoping the sum adds up. Five unrelated initiatives that each consume a team are not
a strategy, however good each one is, because they compete for the same people and nothing ties
them together.

Coherence is also where the strategy becomes expensive. An action that commits a team for a quarter
is a promise somebody will notice being broken. A strategy whose actions commit nothing — "teams
are encouraged to consider reliability" — has not left the second part.

## Testing a draft against the kernel

Three questions, one per part, sort a draft in a few minutes:

| part | the question | what a failing answer looks like |
|---|---|---|
| diagnosis | Could somebody check this against data and find it false? | an opinion, or every problem at once |
| guiding policy | Name one sensible proposal this rules out. | nothing comes to mind |
| coherent actions | Who does this, from when, instead of what? | "all teams", "ongoing", "in addition" |

Run Davi's first draft through the table and it fails all three rows. The next section shows the
version he wrote after a week of reading incident reports instead of collecting wishes.
