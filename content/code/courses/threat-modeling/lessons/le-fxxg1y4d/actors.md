---
title: Actors
version: 1
---

"The attacker" in most threat models is one imagined person: skilled, outside, and interested in
everything. That picture is wrong in a way that matters, because **most harm to a clinic's data is
done by people who already have some access and need no skill at all.** A list of actors replaces
the one imagined person with the real cast.

For each actor, two things decide what they can do: **what access they start with**, and **what
capability they bring**: time, money, skill, patience. Placing them on those two axes shows which
controls would stop which of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l07-actors\" aria-label=\"Actors placed on two axes: how much access they start with, from none to staff, and how much capability they bring, from little to a lot. With no access and little capability: a curious stranger. With no access and some capability: someone running leaked passwords against sign-in pages. With no access and a lot of capability: an extortion group. With a patient’s access: somebody close to a patient, who knows their password or holds their phone. With staff access and little capability: a curious receptionist and a careless physiotherapist. With staff access, gone stale: a former employee whose account still works. With vendor access: an employee of the SMS provider.\"><defs><marker id=\"l07-actors-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 280.0 L700.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-actors-tm-ah-paper-dim)\"></path><path d=\"M90.0 280.0 L90.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-actors-tm-ah-paper-dim)\"></path><text x=\"165.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">none</text><text x=\"315.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a patient’s</text><text x=\"465.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a vendor’s</text><text x=\"615.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">staff</text><text x=\"395.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">access they start with</text><text x=\"82.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">little</text><text x=\"82.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">some</text><text x=\"82.0\" y=\"55.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a lot</text><text x=\"14.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">capability</text><circle cx=\"165.0\" cy=\"250.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"165.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">curious stranger</text><circle cx=\"165.0\" cy=\"150.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"165.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">password-list runner</text><circle cx=\"165.0\" cy=\"55.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"165.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">extortion group</text><circle cx=\"315.0\" cy=\"210.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"315.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">someone close to a patient</text><circle cx=\"465.0\" cy=\"190.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"465.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SMS provider employee</text><circle cx=\"615.0\" cy=\"250.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"615.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">curious receptionist</text><circle cx=\"615.0\" cy=\"215.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"615.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">careless physio</text><circle cx=\"615.0\" cy=\"120.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"615.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">former employee</text><circle cx=\"110.0\" cy=\"312.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"120.0\" y=\"312.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">named in lesson 4’s stage 4 as active now</text></svg>", "caption": "Of the three actors carla’s stage 4 named, one is already inside and needs no skill at all. The grey ones were found by asking who else."}
```

| actor | starts with | wants | what stops them |
|---|---|---|---|
| curious stranger | nothing | to see what is there | almost anything; they give up quickly |
| password-list runner | leaked passwords from other sites | any account that works | a second factor, rate limits, breached-password checks |
| extortion group | nothing, and time | data to ransom, or systems to lock | the whole stack, and backups that work |
| someone close to a patient | the patient's phone, or their password | where and when the patient is, and why | sessions that end, notifications of new sign-ins |
| curious receptionist | a staff account | a neighbour's or a celebrity's record | roles that hide what the job does not need, and an access log somebody reads |
| careless physiotherapist | a staff account | to get the job done quickly | defaults that are safe without effort |
| former employee | an account nobody switched off | access they used to have | leaving procedures that end every account |
| SMS provider employee | every message Vereda sends | whatever is in them | sending less, and a contract that says what they may keep |

### The actor this list adds

**Someone close to a patient** was on nobody's list until daniel told a story at the meeting: a
patient asked the reception never to confirm their sessions by phone, because a former partner
had called pretending to be them. It is the actor with the most to gain from a physiotherapy
clinic's data and the least technical skill, and nothing in the design was built with that person
in mind. The reminder SMS, T08, matters more once that actor is on the list.

### Actors are not personas

An actor here is a role with access and a motive, not a character with a name and a backstory.
Inventing detailed attacker personas is a way to spend a session on fiction. The test of an actor
on the list is whether it changes a decision: if adding it does not make anybody ask a new question
about the design, it is not pulling its weight.
