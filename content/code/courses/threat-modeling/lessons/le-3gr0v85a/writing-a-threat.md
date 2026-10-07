---
title: Writing a threat down
version: 1
---

Half the threats written in a first session are not threats. "SQL injection." "The database." "No
MFA." Each names a topic, and a topic cannot be checked off: nobody can say whether "the database"
has been dealt with. **A threat is written as somebody doing something to something, with a
result**, and every part of that sentence is there because a later step needs it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l03-threat-anatomy\" aria-label=\"A threat statement in four parts, using T07. Who: a signed-in patient. Does what: changes the exam number in the address. To what: another patient’s exam PDF. With what result: downloads it, which discloses health data. Under it, the STRIDE letter I and the element, flow 2.\"><defs><marker id=\"l03-threat-anatomy-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">who</text><rect x=\"20.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a signed-in</text><text x=\"100.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">patient</text><path d=\"M180.0 68.0 L192.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"272.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">does what</text><rect x=\"192.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">changes the exam</text><text x=\"272.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">number in the address</text><path d=\"M352.0 68.0 L364.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"444.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">to what</text><rect x=\"364.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"444.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">another patient’s</text><text x=\"444.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exam PDF</text><path d=\"M524.0 68.0 L536.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"616.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">with what result</text><rect x=\"536.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"616.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">downloads it: health</text><text x=\"616.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data disclosed</text><rect x=\"20.0\" y=\"125.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">STRIDE: I</text><rect x=\"192.0\" y=\"125.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">element: flow 2</text><text x=\"370.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">filed as T07</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">If one part is missing, nobody can tell whether the threat has been dealt with.</text></svg>", "caption": "A threat names somebody doing something to something, and what happens then. The letter and the element say where it lives."}
```

| part | why it is needed | missing, it looks like |
|---|---|---|
| **who** | decides how likely it is, and which controls apply: a patient, a stranger, a staff member | "an attacker can read exams" (which attacker? signed in or not?) |
| **does what** | the action, at the level of the design | "via IDOR" (a technique name, not an action) |
| **to what** | the asset, which decides the impact | "access data" (whose? which data?) |
| **with what result** | the consequence a person would care about | "a security issue" |

Two rules keep the sentences honest:

**Name the design, not the bug.** "The download route does not check that the exam belongs to the
signed-in patient" is a statement about a missing check, which a design can fix. "There is an
IDOR on `/exams/{id}`" is a finding about code that may or may not exist yet. Before the code is
written, only the first can be true.

**One threat per sentence.** "Attackers could spoof, tamper with and read the webhook" is three
threats with three different fixes. Written as one, the first fix gets it ticked off and the other
two disappear with it.

### Rewriting the first drafts

The first session's notes, and what each became:

| first draft | rewritten | |
|---|---|---|
| "webhook security" | anybody who finds the webhook address can mark a booking paid | T01 |
| "no MFA" | a phished receptionist password, and no second factor to stop its use | T03 |
| "IDOR" | a patient changes the exam number in the address and downloads somebody else's PDF | T07 |
| "DoS" | uploads have no size limit; large files fill the storage | T10 |
| "the database" | (nothing: it was a topic, and the specific threats were T05, T09 and T13) | |

The last row is the useful one. "The database" felt like a finding, and when the team tried to
write it as a sentence it turned out to be three different threats from three different people,
each with its own fix. A topic that cannot be written as a sentence is a sign that the work is not
finished yet.
