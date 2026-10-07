---
title: Abuse cases
version: 1
---

A use case says what somebody does with the system to get what they want: *a patient books a
session*. An **abuse case**, or **misuse case**, is the same feature seen by somebody who wants
something the feature was not meant to give: *a patient books and cancels in a loop so that Vereda
pays for a hundred text messages*. The idea was published by Guttorm Sindre and Andreas Opdahl in
the early 2000s, and Gary McGraw made it a standard part of building security in. It is the most
useful bridge there is between a threat model and the people who write features, because **it is
written in the language they already use.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l07-misuse\" aria-label=\"A use case diagram with misuse cases. The patient performs book a session and receive a reminder. A misuser performs two misuse cases, drawn dark: book and cancel in a loop, which threatens receive a reminder by flooding SMS, and read another patient’s exam, which threatens view my exams. Two mitigating use cases, drawn with a green border: limit bookings per account per hour, which mitigates the loop, and check the exam belongs to the signed-in patient, which mitigates the second.\"><defs><marker id=\"l07-misuse-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-misuse-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"83.0\" width=\"90.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Patient</text><rect x=\"615.0\" y=\"143.0\" width=\"90.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Misuser</text><ellipse cx=\"250\" cy=\"60\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">book a session</text><ellipse cx=\"250\" cy=\"140\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">receive a reminder</text><ellipse cx=\"250\" cy=\"220\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">view my exams</text><ellipse cx=\"480\" cy=\"110\" rx=\"88\" ry=\"24\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">book and cancel</text><text x=\"480.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">in a loop</text><ellipse cx=\"480\" cy=\"230\" rx=\"88\" ry=\"24\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"223.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">read another</text><text x=\"480.0\" y=\"236.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">patient’s exam</text><ellipse cx=\"480\" cy=\"30\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"23.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">limit bookings per</text><text x=\"480.0\" y=\"36.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">account per hour</text><ellipse cx=\"250\" cy=\"280\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"273.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">check the exam belongs</text><text x=\"250.0\" y=\"286.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to the signed-in patient</text><path d=\"M105.0 95.0 L162.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M105.0 105.0 L162.0 136.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 117.0 L165.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M615.0 155.0 L568.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M615.0 168.0 L568.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M392.0 118.0 L338.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-amber)\"></path><text x=\"372.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">threatens</text><path d=\"M392.0 228.0 L338.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-amber)\"></path><text x=\"366.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">threatens</text><path d=\"M480.0 54.0 L480.0 86.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-phosphor)\"></path><text x=\"488.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">mitigates</text><path d=\"M338.0 268.0 L420.0 248.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-phosphor)\"></path><text x=\"392.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">mitigates</text></svg>", "caption": "A misuse case sits in the same picture as the feature it attacks, so the people who own the feature see it."}
```

The notation adds three things to an ordinary use case diagram:

- a **misuser**, drawn like an actor, standing for one of the actors of the previous section;
- **misuse cases**, drawn as dark ovals, each one something the misuser does;
- two relationships: a misuse case **threatens** a use case, and a **mitigating** use case, a
  feature added because of the threat, mitigates the misuse case.

The last one is the point. A mitigation drawn as a use case is a feature with an owner, a place in
the backlog and acceptance criteria, rather than a security note that nobody schedules.

### Writing one

An abuse case is a short story with four parts, which are the threat statement of lesson 3 told
from the actor's side:

| part | example |
|---|---|
| **the actor** | a signed-in patient |
| **what they do, in the feature's own terms** | opens "my exams" and changes the exam number in the address |
| **what they get** | another patient's exam report |
| **what the system should do instead** | answer as if the exam did not exist, and record the attempt |

The fourth line is what makes an abuse case more than a threat. It says what *right* looks like,
and that sentence is half of a requirement already. Lesson 8 finishes the job.

### Where they come from

From three places, in roughly this order of yield:

1. **Every use case, crossed with every actor.** "A patient books a session" asked of the
   password-list runner, the person close to a patient and the curious receptionist gives three
   different abuse cases.
2. **Every entry point from lesson 6** that anyone can reach.
3. **What happened elsewhere**: carla's stage 4 notes, incident reports from similar clinics, the
   complaints reception receives.
